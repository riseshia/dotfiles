---
name: workflow
description: Run a development task as an event-driven state machine (plan → plan-approve → implement → validate → minor-fix/recheck → open-pr → followup → done). A thin orchestrator fires named transitions via a CLI that enforces the plan-approve human gate and bounded rework/continue loops, reads a per-state prompt for each node, delegates heavy work-states to fresh workers (Agent tool or claude -p) over a file-based handoff, and ships via a Draft PR. Use when the user wants to run a non-trivial task end-to-end with minimal supervision.
user-invocable: true
arguments: task
version: 0.7.0
license: CC0-1.0
---

# Workflow

Run a development task as an **event-driven finite state machine**. Each state is a **node with its own prompt file** in `nodes/`. The agent does the work for the current state, then **fires a named event** (`workflow.sh fire <event>`); the CLI applies the matching transition, enforcing the **plan-approve human gate** and **bounded loops** (rework ×5, continue ×1). The agent runs autonomously and stops for the human at one gate state: **plan-approve**. Review of the change happens on the Draft PR.

Design: deterministic engineering for the control flow, LLM judgment for the work.

- **State lives in files** (`.workflow/`: `state`, `task.md`, `plan.md`, `feedback.md` — the reason for a `rework`/`continue` loop, written by the routing state and consumed by `implement` — and `history.log`, the timestamped transition/worker trace that `workflow-retro` reads), so a run survives sub-agents and session resumes.
- **The machine is composable**: states, events, guards, and gates live in the `pipeline` transition table, not in code. Each state has a **separate prompt** (`nodes/<state>.md`) the agent reads on entry.
- **Transitions go through the CLI**, which validates the event, blocks gated events until approved, and enforces attempt-counter guards.
- **The orchestrator stays thin.** Work-states (anything that reads/writes lots of repo content — diffs, tests, git) run in a **worker** with its own context; the orchestrator only drives transitions, holds the human dialogue, and reads each worker's short report. See **Workers** below.

```
●→ plan ⇄[submit/revise] plan-approve《gate》──resume──> implement ──submit──> validate
                                                  ↑  ↑                          │
                                        rework ×5 │  │ rework ×5    recheck / minor / rework
                                                  │  └── minor-fix ──recheck──┐  │
                                                  │                           ▼  ▼
                              implement <──continue ×1── recheck <────────────────
                                                          │
                                                          └── pr ──> open-pr ──submit──> followup ──submit──> done
   (any non-terminal) ──exit──> exited
```

---

## Start

```
bash <skill-dir>/workflow.sh start "<task description>"
```

Use `{task}` from the invocation as the description; if empty, ask the user for a one-line task statement first. If a workflow is already in progress, `show` it and resume from the current state or `abort` first.

## The run loop

Repeat until the state is terminal (`done` / `exited`):

1. `bash <skill-dir>/workflow.sh show` — read the current state and its fireable events.
2. Read `<skill-dir>/nodes/<state>.md` and **execute that state's instructions**. Most states delegate the work to a **worker** (see below) and hand you back a short report; you read only that.
3. Fire the event the node/report indicates: `bash <skill-dir>/workflow.sh fire <event>`. At a gate, **stop for the user first**.

A rejected `fire` (gate not approved, guard exhausted, or invalid event) is a signal to pause and choose — not to retry blindly.

## Workers

States marked `@worker` (plan, implement, validate, minor-fix, recheck, open-pr) do their heavy lifting in a **fresh `claude -p` process**, not in the orchestrator. This is enforced structurally: the worker prompt lives in `workers/<state>.txt`, and the only blessed way to run it is

```
bash <skill-dir>/workflow.sh work
```

which `exec`s `claude -p "$(cat workers/<state>.txt)"`. The orchestrator never reads the raw diff/test/git output — only the worker's final stdout (a short verdict). Its context stays clean across a long run.

- The node prompt for a worker state is a **thin router**: run `workflow.sh work`, read the verdict, then `fire`. **Do not do the work inline** — the orchestrator cannot truly be prevented from it (it keeps its own tools), so treat `workflow.sh work` as mandatory and inline work as a bug.
- Handoff is **file-based** (`.workflow/plan.md`, `.workflow/feedback.md`, the working tree), so a worker — or a resumed session — picks up the contract from disk. Workers only *read* `feedback.md`; the orchestrator is its sole writer/deleter (a few lines, from the verdict it already holds).
- Permissions/tools for the headless worker are passed through env (the org disallows `bypassPermissions`):
  - `WORKFLOW_CLAUDE_BIN` — claude binary (default `claude`)
  - `WORKFLOW_CLAUDE_FLAGS` — e.g. `--permission-mode acceptEdits --allowedTools "Read Edit Write Bash Grep Glob"`
- Non-worker states (`plan-approve`, `followup`) and the human dialogue in `plan` stay in the orchestrator — they are light and user-facing.

Hard guarantee is not possible from the skill alone (the orchestrator retains its tools); for stricter enforcement, run the orchestrator session itself with reduced tools so heavy work *must* go through `workflow.sh work`.

## States

| state | executor | prompt | fires |
|---|---|---|---|
| `plan` | orchestrator dialogue + worker (investigate/draft) | `nodes/plan.md` | `submit` |
| `plan-approve` | orchestrator (light, human gate) | `nodes/plan-approve.md` | `revise` / `resume`. **Human gate state** — `approve` required to leave. |
| `implement` | worker | `nodes/implement.md` | `submit` |
| `validate` | worker | `nodes/validate.md` | `recheck` / `minor` / `rework` (×5) |
| `minor-fix` | worker | `nodes/minor-fix.md` | `recheck` / `rework` (×5) |
| `recheck` | worker | `nodes/recheck.md` | `pr` / `continue` (×1) |
| `open-pr` | worker (via `shia-guides:draft-pr`) | `nodes/open-pr.md` | `submit` |
| `followup` | orchestrator (final report) | `nodes/followup.md` | `submit` |
| `done` | — | — | terminal |
| `exited` | — | — | terminal (`fire exit`) |

---

## CLI reference

```
workflow.sh start "<task>"   start at the @initial state; appends .workflow/ to .gitignore
workflow.sh show             current state, metadata, attempt counters, fireable events
workflow.sh work             run the current @worker state in a fresh `claude -p` process
workflow.sh fire <event>     apply a transition (enforces gates + guards); `exit` -> exited
workflow.sh approve          grant human sign-off to leave the current gate state
workflow.sh set <k> <v>      record metadata: branch | plan_file | pr_url
workflow.sh abort            remove all workflow state
```

## Composability

The machine is data, not code — the `pipeline` transition table:

```
@initial  plan
@terminal done
@terminal exited
@gate     plan-approve
@worker   implement

<from> <event> <to> [counter=NAME max=N] [gate=1]
```

- `@gate <state>`: a human-gate state. Leaving it (any event except `exit`) requires a prior `workflow.sh approve`, which is consumed on firing.
- `@worker <state>`: a work-state run via `workflow.sh work` (`claude -p` on `workers/<state>.txt`). Adding one needs a matching `workers/<state>.txt` as well as `nodes/<state>.md`.
- `counter=NAME max=N`: a bounded loop. The event fires only while the named counter `< N`, and increments it. Same `NAME` is shared across edges (e.g. `rework` from both `validate` and `minor-fix`).
- `gate=1`: per-edge gate (same approval mechanism, but on a single transition rather than the whole state).
- `exit` is implicit from any non-terminal state.

To recompose: edit `pipeline` (add/remove/reorder states, retarget events, change guards, move the gate/workers); ensure every `from` state has a `nodes/<state>.md`, and every `@worker` state also has a `workers/<state>.txt`. `workflow.sh` reloads the table on every call. The `workflow-retro` skill can propose and apply such edits.

## Constraints

- Never hand-edit `.workflow/state`. State changes go through the CLI only.
- The plan-approve gate is mandatory unless the user explicitly pre-authorizes skipping it.
- Stay within the approved plan. If implementation must diverge materially, route through `rework` or pause.
- Do not classify a state as passing while verification is failing.
- Keep `.workflow/` out of commits.
