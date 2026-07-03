#!/usr/bin/env bash
# State-machine driver for the dev-workflow skill.
#
# This is an event-driven finite state machine: the agent fires NAMED events
# (`workflow.sh fire <event>`) and the CLI applies the matching transition,
# enforcing gates (human approval) and bounded-loop guards (attempt counters).
# Transitions are performed deterministically here so the LLM never rewrites
# state by hand. State is persisted under .workflow/ so it survives sub-agents
# and session resumes.
#
# Work-states (@worker) are executed in a fresh `claude -p` process via
# `workflow.sh work`, so their heavy context never lands in the orchestrator.
# The machine (states, events, guards, gates, workers) is NOT hardcoded: it is
# read from the `pipeline` transition table next to this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_FILE="$SCRIPT_DIR/pipeline"
WORKERS_DIR="$SCRIPT_DIR/workers"

WF_DIR=".workflow"
STATE_FILE="$WF_DIR/state"
TASK_FILE="$WF_DIR/task.md"
HISTORY_FILE="$WF_DIR/history.log"

EXIT_STATE="exited"

die() { echo "error: $*" >&2; exit 1; }

# --- transition table (loaded from the composable `pipeline` file) -----------
INITIAL=""
TERMINALS=""
GATES=""
WORKERS=""
TR=()   # each entry: "from event to flag1 flag2 ..."
load_pipeline() {
  [ -f "$PIPELINE_FILE" ] || die "pipeline file not found: $PIPELINE_FILE"
  local line key
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ""|\#*) continue ;;
    esac
    # shellcheck disable=SC2086
    set -- $line
    key="$1"
    case "$key" in
      @initial)  INITIAL="$2" ;;
      @terminal) TERMINALS="$TERMINALS $2" ;;
      @gate)     GATES="$GATES $2" ;;
      @worker)   WORKERS="$WORKERS $2" ;;
      *)         TR+=("$line") ;;
    esac
  done < "$PIPELINE_FILE"
  [ -n "$INITIAL" ] || die "pipeline has no @initial state"
  [ "${#TR[@]}" -gt 0 ] || die "pipeline has no transitions"
}

is_terminal()    { case " $TERMINALS " in *" $1 "*) return 0 ;; esac; return 1; }
is_gate_state()  { case " $GATES "     in *" $1 "*) return 0 ;; esac; return 1; }
is_worker_state(){ case " $WORKERS "   in *" $1 "*) return 0 ;; esac; return 1; }

require_state() {
  [ -f "$STATE_FILE" ] || die "workflow not started. run: $0 start \"<task>\""
}

get() {
  [ -f "$STATE_FILE" ] || return 0
  sed -n "s/^$1=//p" "$STATE_FILE" | head -1
}

set_kv() {
  local key="$1" val="$2" tmp
  tmp=$(mktemp)
  if [ -f "$STATE_FILE" ]; then
    grep -v "^$key=" "$STATE_FILE" > "$tmp" || true
  fi
  echo "$key=$val" >> "$tmp"
  mv "$tmp" "$STATE_FILE"
}

# Append a timestamped line to the run history — the durable evidence trail
# workflow-retro reads (transition path, loop counts, wall-clock per state).
log_event() {
  [ -d "$WF_DIR" ] || return 0
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$HISTORY_FILE"
}

# Parse "key=val" flags from a transition's trailing tokens into globals.
F_TO=""; F_COUNTER=""; F_MAX=""; F_GATE=""
parse_transition() {
  # args: from event to [flags...]
  F_TO="$3"; F_COUNTER=""; F_MAX=""; F_GATE=""
  shift 3
  local tok
  for tok in "$@"; do
    case "$tok" in
      counter=*) F_COUNTER="${tok#counter=}" ;;
      max=*)     F_MAX="${tok#max=}" ;;
      gate=*)    F_GATE="${tok#gate=}" ;;
    esac
  done
}

# Find a transition for (state,event). Sets F_* on success; returns 1 if none.
find_transition() {
  local state="$1" event="$2" entry from ev
  for entry in "${TR[@]}"; do
    # shellcheck disable=SC2086
    set -- $entry
    from="$1"; ev="$2"
    if [ "$from" = "$state" ] && [ "$ev" = "$event" ]; then
      parse_transition "$@"
      return 0
    fi
  done
  return 1
}

events_for() {
  local state="$1" entry from
  for entry in "${TR[@]}"; do
    # shellcheck disable=SC2086
    set -- $entry
    from="$1"
    [ "$from" = "$state" ] && echo "$entry"
  done
}

ensure_gitignored() {
  local gi=".gitignore"
  if [ -f "$gi" ] && grep -qx ".workflow/" "$gi"; then
    return 0
  fi
  printf '%s\n' ".workflow/" >> "$gi"
}

cmd_start() {
  local task="${1:-}" branch dirty=""
  [ -n "$task" ] || die "usage: $0 start \"<task description>\""
  [ -f "$STATE_FILE" ] && die "workflow already in progress (state=$(get state)). run '$0 abort' to reset."
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    [ -n "$(git status --porcelain 2>/dev/null)" ] && dirty=yes
    if [ -n "$dirty" ]; then
      echo "warning: working tree is dirty. unrelated changes may end up in the PR commits — consider stashing or committing them first." >&2
    fi
    branch=$(git branch --show-current 2>/dev/null || true)
    case "$branch" in
      main | master | staging)
        echo "warning: currently on '$branch'. implement must create a feature branch before touching code." >&2 ;;
    esac
  fi
  mkdir -p "$WF_DIR"
  : > "$STATE_FILE"
  : > "$HISTORY_FILE"
  set_kv state "$INITIAL"
  set_kv approved no
  set_kv plan_file ""
  set_kv branch ""
  set_kv pr_url ""
  printf '%s\n' "$task" > "$TASK_FILE"
  ensure_gitignored
  log_event "start $INITIAL${dirty:+ (dirty working tree)}"
  cmd_show
}

print_events() {
  local state="$1" entry to annot cnt
  echo "events:"
  if is_terminal "$state"; then
    echo "  (terminal state — none)"
    return
  fi
  while read -r entry; do
    [ -n "$entry" ] || continue
    parse_transition $entry
    to="$F_TO"; annot=""
    if [ -n "$F_COUNTER" ]; then
      cnt=$(get "attempt_$F_COUNTER"); cnt=${cnt:-0}
      annot="$annot [guard $F_COUNTER $cnt/$F_MAX]"
    fi
    [ "$F_GATE" = "1" ] && annot="$annot [gate: needs approve]"
    set -- $entry
    printf '  %-10s -> %s%s\n' "$2" "$to" "$annot"
  done < <(events_for "$state")
  echo "  exit       -> $EXIT_STATE"
}

cmd_show() {
  require_state
  local cur
  cur=$(get state)
  echo "=== dev-workflow ==="
  echo "task     : $(head -1 "$TASK_FILE" 2>/dev/null)"
  echo "state    : $cur"
  echo "approved : $(get approved)"
  echo "branch   : $(get branch)"
  echo "plan_file: $(get plan_file)"
  echo "pr_url   : $(get pr_url)"
  local r c
  r=$(get attempt_rework); c=$(get attempt_continue)
  [ -n "$r$c" ] && echo "attempts : rework=${r:-0} continue=${c:-0}"
  if is_gate_state "$cur"; then
    echo
    echo "HUMAN GATE: this state requires 'approve' before any fire (except exit)."
  fi
  if is_worker_state "$cur"; then
    echo
    echo "WORKER STATE: run '$0 work' (executes workers/$cur.txt via claude -p);"
    echo "do not do the work inline. Then read the report and 'fire' accordingly."
  fi
  echo
  print_events "$cur"
}

cmd_work() {
  require_state
  local cur bin pf
  cur=$(get state)
  is_terminal "$cur" && die "state '$cur' is terminal. nothing to run."
  is_worker_state "$cur" || die "state '$cur' is handled by the orchestrator, not a worker. follow nodes/$cur.md directly."
  pf="$WORKERS_DIR/$cur.txt"
  [ -f "$pf" ] || die "worker prompt missing: $pf"
  bin="${WORKFLOW_CLAUDE_BIN:-claude}"
  command -v "$bin" >/dev/null 2>&1 || die "'$bin' not found on PATH. install the Claude Code CLI, or set WORKFLOW_CLAUDE_BIN."
  log_event "work $cur"
  local flags="${WORKFLOW_CLAUDE_FLAGS:---permission-mode auto}"
  echo "[workflow] state=$cur -> running worker in a fresh process: $bin -p (workers/$cur.txt) $flags" >&2
  # The worker runs in its own process/context; only its final stdout returns here.
  # Strip the Claude Code session markers so it starts as a fresh top-level
  # invocation instead of being detected as a nested session.
  # WORKFLOW_CLAUDE_FLAGS overrides the default flags. Values are split on
  # whitespace only — embedded quotes are NOT unwrapped, so multi-word values
  # for a single flag will break.
  # shellcheck disable=SC2086
  env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_SESSION_ID \
      -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_EXECPATH \
      "$bin" -p "$(cat "$pf")" $flags < /dev/null
}

cmd_fire() {
  require_state
  local event="${1:-}" cur cnt reason
  [ -n "$event" ] || die "usage: $0 fire <event> [reason]"
  shift || true
  reason="$*"
  cur=$(get state)
  is_terminal "$cur" && die "state '$cur' is terminal. nothing to fire."

  if [ "$event" = "exit" ]; then
    set_kv state "$EXIT_STATE"
    log_event "fire $cur exit $EXIT_STATE${reason:+ -- $reason}"
    echo "-> $cur --exit--> $EXIT_STATE"
    cmd_show
    return
  fi

  if ! find_transition "$cur" "$event"; then
    log_event "reject $cur $event (no such transition)"
    echo "error: no '$event' transition from '$cur'." >&2
    echo "valid events from '$cur':" >&2
    print_events "$cur" >&2
    exit 1
  fi

  # gate: require prior approval (gate state, or a gate=1 edge)
  local gated=no
  is_gate_state "$cur" && gated=yes
  [ "$F_GATE" = "1" ] && gated=yes
  if [ "$gated" = "yes" ] && [ "$(get approved)" != "yes" ]; then
    log_event "reject $cur $event (gate not approved)"
    die "state '$cur' is a human gate. get user sign-off, then '$0 approve' before '$0 fire $event'."
  fi

  # bounded-loop guard
  if [ -n "$F_COUNTER" ]; then
    cnt=$(get "attempt_$F_COUNTER"); cnt=${cnt:-0}
    if [ "$cnt" -ge "$F_MAX" ]; then
      log_event "reject $cur $event (guard $F_COUNTER exhausted $cnt/$F_MAX)"
      die "guard '$F_COUNTER' exhausted ($cnt/$F_MAX). '$event' not allowed. choose another event or 'exit'."
    fi
    set_kv "attempt_$F_COUNTER" "$((cnt + 1))"
  fi

  set_kv state "$F_TO"
  [ "$gated" = "yes" ] && set_kv approved no   # consume the approval
  log_event "fire $cur $event $F_TO${reason:+ -- $reason}"
  echo "-> $cur --$event--> $F_TO"
  cmd_show
}

cmd_approve() {
  require_state
  local cur
  cur=$(get state)
  if ! is_gate_state "$cur" && ! events_for "$cur" | grep -q 'gate=1'; then
    die "state '$cur' has no gate. nothing to approve."
  fi
  set_kv approved yes
  log_event "approve $(get state)"
  echo "-> approved. the gate is unlocked (consumed on the next gated fire)."
}

cmd_set() {
  require_state
  [ -n "${1:-}" ] && [ $# -ge 2 ] || die "usage: $0 set <key> <value>   (key: branch|plan_file|pr_url)"
  case "$1" in
    branch | plan_file | pr_url) set_kv "$1" "$2"; echo "-> set $1=$2" ;;
    *) die "unknown key '$1'. allowed: branch, plan_file, pr_url" ;;
  esac
}

cmd_abort() {
  [ -d "$WF_DIR" ] || { echo "no workflow to abort."; return; }
  rm -rf "$WF_DIR"
  echo "-> workflow state removed."
}

# Static consistency check across the three surfaces: pipeline <-> nodes/ <-> workers/.
# Run after editing the pipeline (e.g. via workflow-retro) to catch drift early.
cmd_lint() {
  local errors=0 warnings=0
  lint_err()  { echo "lint error: $*" >&2; errors=$((errors + 1)); }
  lint_warn() { echo "lint warning: $*" >&2; warnings=$((warnings + 1)); }

  local entry from ev to tok pair name max known state
  local seen_pairs="" froms="" tstates="" counter_defs=""
  for entry in "${TR[@]}"; do
    # shellcheck disable=SC2086
    set -- $entry
    if [ $# -lt 3 ]; then
      lint_err "malformed transition line: '$entry'"
      continue
    fi
    from="$1"; ev="$2"; to="$3"; shift 3
    pair="$from:$ev"
    case " $seen_pairs " in *" $pair "*) lint_err "duplicate transition '$from $ev'" ;; esac
    seen_pairs="$seen_pairs $pair"
    froms="$froms $from"
    tstates="$tstates $from $to"
    is_terminal "$from" && lint_err "terminal state '$from' has an outgoing transition ('$ev')"
    name=""; max=""
    for tok in "$@"; do
      case "$tok" in
        counter=*) name="${tok#counter=}" ;;
        max=*)     max="${tok#max=}" ;;
        gate=*)    : ;;
        *)         lint_err "unknown flag '$tok' on transition '$from $ev'" ;;
      esac
    done
    if [ -n "$name" ]; then
      [ -n "$max" ] || lint_err "transition '$from $ev' has counter=$name but no max="
      # shellcheck disable=SC2086
      known=$(printf '%s\n' $counter_defs | sed -n "s/^$name=//p" | head -1)
      if [ -n "$known" ] && [ -n "$max" ] && [ "$known" != "$max" ]; then
        lint_err "counter '$name' has conflicting max values ($known vs $max)"
      fi
      counter_defs="$counter_defs $name=$max"
    elif [ -n "$max" ]; then
      lint_err "transition '$from $ev' has max= but no counter="
    fi
  done

  # every non-terminal state needs a node prompt; states inside the graph must not dead-end
  # shellcheck disable=SC2086
  for state in $(printf '%s\n' $tstates $INITIAL $GATES $WORKERS | sort -u); do
    is_terminal "$state" && continue
    [ -f "$SCRIPT_DIR/nodes/$state.md" ] || lint_err "missing nodes/$state.md for state '$state'"
  done
  # shellcheck disable=SC2086
  for state in $(printf '%s\n' $tstates | sort -u); do
    is_terminal "$state" && continue
    case " $froms " in *" $state "*) ;; *) lint_err "dead end: non-terminal state '$state' has no outgoing transitions" ;; esac
  done

  case " $froms " in *" $INITIAL "*) ;; *) lint_err "@initial state '$INITIAL' has no outgoing transitions" ;; esac
  is_terminal "$EXIT_STATE" || lint_warn "exit target '$EXIT_STATE' is not declared @terminal in the pipeline"

  for state in $WORKERS; do
    [ -f "$WORKERS_DIR/$state.txt" ] || lint_err "missing workers/$state.txt for @worker state '$state'"
    case " $tstates " in *" $state "*) ;; *) lint_warn "@worker state '$state' never appears in a transition" ;; esac
  done
  for state in $GATES; do
    case " $froms " in *" $state "*) ;; *) lint_warn "@gate state '$state' is never a from-state (gate has no effect)" ;; esac
  done
  for state in $TERMINALS; do
    [ "$state" = "$EXIT_STATE" ] && continue   # reached via the implicit `exit` event
    case " $tstates " in *" $state "*) ;; *) lint_warn "@terminal state '$state' is never reached by a transition" ;; esac
  done

  if [ "$errors" -gt 0 ]; then
    echo "lint: $errors error(s), $warnings warning(s)." >&2
    exit 1
  fi
  # shellcheck disable=SC2086
  echo "lint: OK ($(printf '%s\n' $tstates $INITIAL $GATES $WORKERS | sort -u | wc -l) states, ${#TR[@]} transitions, $warnings warning(s))"
}

usage() {
  cat <<EOF
dev-workflow state machine (transition table: $PIPELINE_FILE)

usage:
  $0 start "<task>"     start a new workflow at the @initial state
  $0 show               print current state, metadata, and fireable events (alias: status)
  $0 work               run the current worker-state in a fresh 'claude -p' process
  $0 fire <event> [reason]  apply a transition (enforces gates + guards); the reason lands in history.log
  $0 approve            grant human sign-off to leave the current gate state
  $0 set <key> <value>  record metadata (branch|plan_file|pr_url)
  $0 lint               check pipeline <-> nodes/ <-> workers/ consistency
  $0 abort              remove all workflow state (alias: reset)

initial : $INITIAL
terminal:$TERMINALS
gates   :$GATES (leaving requires 'approve')
workers :$WORKERS (run via '$0 work')
'exit' is available from any non-terminal state -> $EXIT_STATE

env:
  WORKFLOW_CLAUDE_BIN    claude binary to use (default: claude)
  WORKFLOW_CLAUDE_FLAGS  extra flags for 'claude -p' (permissions/tools)
EOF
}

main() {
  load_pipeline
  local cmd="${1:-show}"
  shift || true
  case "$cmd" in
    start) cmd_start "${1:-}" ;;
    show | status) cmd_show ;;
    work) cmd_work ;;
    fire) cmd_fire "$@" ;;
    approve) cmd_approve ;;
    set) cmd_set "$@" ;;
    lint) cmd_lint ;;
    abort | reset) cmd_abort ;;
    -h | --help | help) usage ;;
    *) die "unknown command '$cmd'. run '$0 help'." ;;
  esac
}

main "$@"
