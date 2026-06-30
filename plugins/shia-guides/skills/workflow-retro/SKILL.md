---
name: workflow-retro
description: Run a session-level retrospective after a shia-guides:workflow run and propose concrete, composable improvements to the workflow's three surfaces — the `pipeline` transition table, `nodes/*.md` orchestrator routers, and `workers/*.txt` worker prompts. Grounds findings in the run's `.workflow/history.log` (timestamped transition/worker trace), state counters, and the shipped diff. Use when a run is finished (before `abort`) and you want to turn what happened into a better workflow.
user-invocable: true
version: 0.2.0
license: CC0-1.0
---

# Workflow Retro

A session-level retrospective for the `shia-guides:workflow` skill. It reflects on how a run went and turns friction into **concrete edits to one of three surfaces**:

- `pipeline` — the state machine (states, events, guards, `@gate`, `@worker`).
- `nodes/<state>.md` — the **orchestrator's** routing for a state (which event to fire from a verdict).
- `workers/<state>.txt` — the prompt a `claude -p` **worker** actually runs. Most prompt-quality friction lives here.

Run it **before `workflow.sh abort`**, while `.workflow/` still exists. `<workflow-skill-dir>` is the sibling `workflow` skill dir (`../workflow` relative to this skill).

## What you can and cannot see

By design, work-states run in isolated `claude -p` processes, so the orchestrator only ever saw each worker's short **verdict**, never its internal reasoning, diffs, or tool calls. Ground the retro in what is actually observable:

- **`.workflow/history.log`** — the durable, timestamped trace: `start`, every `work <state>`, every `fire <from> <event> <to>`, every `approve`. This is the primary evidence: the exact path taken, **loop counts** (`grep 'rework'` / `'continue'`), and **wall-clock per state** (timestamp deltas — the "how long did it take" signal).
- **`bash <workflow-skill-dir>/workflow.sh show`** — final state, `attempt_*` counters, branch, pr_url.
- **`.workflow/plan.md` / `task.md`** — what was planned; **`.workflow/feedback.md`** if a loop was mid-flight (the last rework/continue reason).
- **This session's transcript** (if the retro runs in the same session) — the verdicts you relayed, the human dialogue at `plan` / `plan-approve`, any `implement` escalation.
- **The shipped change** — `git diff` / the PR: what landed vs the plan.
- **Cannot see**: a worker's internal reasoning. If a worker's behavior is the suspect, infer from its verdict + the diff, or re-run that worker with logging — do not invent what it "must have done".

## Steps

1. **Reconstruct the timeline** from `history.log`: states traversed, loop counts, time per state, human touchpoints, outcome (PR/verification). Factual.
2. **Identify friction**, each tied to evidence, using this architecture's failure modes:
   - **Loop thrash** — high `rework`/`continue` count. Which worker prompt is mis-calibrated? (e.g. `workers/implement.txt` missing a constraint, or `workers/validate.txt`'s severity bar wrong so it kicks back too readily.)
   - **Misrouting** — a `validate` verdict (CLEAN/MINOR/SIGNIFICANT) or the minor↔rework boundary was wrong → the boundary wording in `workers/validate.txt` + `nodes/validate.md`.
   - **Gate friction** — `plan-approve` too heavy or rubber-stamped; `plan` dialogue asked things the code answers, or asked too little (so it surfaced later as an `implement` escalation).
   - **Worker failure** — `claude -p` permission/flag problems, or a worker that couldn't do its job → `WORKFLOW_CLAUDE_FLAGS` or the worker prompt.
   - **Scope** — out-of-scope work slipped through → constraints in `workers/implement.txt`.
   - **Wasted time** — a slow or redundant state visible in the `history.log` durations (e.g. `recheck` re-running a full suite on the clean path).
3. **Propose changes** — concrete, minimal, on the right surface:
   - `workers/<state>.txt` — the worker prompt (most prompt-quality fixes land here; quote the line).
   - `nodes/<state>.md` — the orchestrator's routing/decision for a state.
   - `pipeline` — states/events/guards (`counter`/`max`)/`@gate`/`@worker`.
   - Mark project-specific one-offs that should NOT be baked into the skill.
4. **Present**: timeline (3-5 lines, incl. durations + loop counts), top friction, proposed edits as a short list — recommend, don't just enumerate.
5. **Apply on approval.** Keep edits surgical. A new `@worker` state needs both `nodes/<state>.md` and `workers/<state>.txt`. Re-validate: `bash <workflow-skill-dir>/workflow.sh help` (loads the table; errors if broken), and confirm every `from` state has a `nodes/<state>.md` and every `@worker` has a `workers/<state>.txt`. These are committed skill files — after applying, suggest committing the change.

## Output format

```
## Retrospective

### What happened
- <timeline from history.log: path, loop counts, time per state, outcome — 3-5 lines>

### Friction
1. <issue> — <evidence: a history.log line / counter / verdict / diff>
2. ...

### Proposed changes
- `workers/<state>.txt`: <edit> — <why>
- `nodes/<state>.md`: <edit> — <why>
- `pipeline`: <edit> — <why>
- (out of scope for the skill: <one-off>)

### Recommendation
<which to apply first, in one or two sentences>
```

## Constraints

- Ground every friction point in `history.log` / counters / a relayed verdict / the diff — not vibes, and not assumptions about worker internals you could not see.
- Keep edits minimal and composable — change `pipeline` / `nodes` / `workers`, not the `workflow.sh` control logic, unless a real defect is found there.
- Do not apply edits without user approval. Applied edits change the installed skill for every future run — commit them deliberately.
- Distinguish workflow-level improvements (bake into the skill) from project-specific one-offs (do not).
