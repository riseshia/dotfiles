---
name: workflow-retro
description: Run a session-level retrospective after a dev-workflow run (or any working session) and propose concrete, composable adjustments to the workflow itself — the `pipeline` file and `nodes/*.md` prompts of the shia-guides:workflow skill. Use when a task is finished and you want to capture what worked, what caused friction, and improve the workflow before the next run.
user-invocable: true
version: 0.1.0
license: CC0-1.0
---

# Workflow Retro

A session-level retrospective for the `shia-guides:workflow` skill. It reflects on how the run went and turns friction into **concrete edits to the composable pipeline** (`pipeline` + `nodes/*.md`), so the workflow gets better each time.

Run this at the end of a session — typically when the workflow reaches `done`, or any time the user wants to tune the process.

## Inputs

Gather evidence before judging. Prefer facts from this session over recollection:

1. Workflow state, if present: `bash <workflow-skill-dir>/workflow.sh show` and `.workflow/plan.md`, `.workflow/task.md`.
2. What actually happened this session: which states ran, where the human had to intervene beyond the plan/plan-approve dialogue, where verification failed and why, where the sub-agent diverged from the plan, and any rework/continue loops.
3. The current pipeline definition and node prompts (`pipeline`, `nodes/*.md`).

`<workflow-skill-dir>` is the sibling `workflow` skill directory (`../workflow` relative to this skill).

## Steps

1. **Reconstruct the timeline.** Briefly: task → states traversed → human touchpoints → outcome (PR URL / verification result). Keep it factual.
2. **Identify friction**, each tied to evidence (a state, a file, a moment in the session):
   - Where did the agent stall, loop, or need correction?
   - Did a node prompt under- or over-specify, causing rework?
   - Was the gate in the right place (too early / too late / missing)?
   - Did `implement` get enough context, or did the sub-agent guess?
   - Was anything done out of scope, or missed?
3. **Propose changes** — concrete and minimal. For each, name the target and the edit:
   - `pipeline` (transition table): add/remove/reorder a state, retarget an event, change a guard (`counter`/`max`), or move the gate (`@gate`) / worker (`@worker`).
   - `nodes/<state>.md`: tighten the orchestrator's routing for a state (quote the line to change).
   - `workers/<state>.txt`: tighten the prompt the `claude -p` worker actually runs (this is usually where under/over-specification that caused rework lives).
   - Note anything that is a one-off (project-specific) and should NOT be baked into the skill.
4. **Present** the retro to the user: timeline (3-5 lines), top friction points, and the proposed edits as a short list. Recommend, don't just enumerate.
5. **Apply on approval.** Only after the user agrees, edit `pipeline` / `nodes/*.md`. Keep edits surgical. If a proposed state is added, also create its `nodes/<state>.md`. Re-validate: `bash <workflow-skill-dir>/workflow.sh help` (it loads the table and errors on a broken one), and confirm every `from` state has a matching node file.

## Output format

```
## Retrospective

### What happened
- <timeline, 3-5 lines>

### Friction
1. <issue> — <evidence: state/file/moment>
2. ...

### Proposed changes
- `pipeline`: <edit> — <why>
- `nodes/<state>.md`: <edit> — <why>
- (out of scope for the skill: <one-off>)

### Recommendation
<which to apply first, in one or two sentences>
```

## Constraints

- Ground every friction point in something that actually happened this session. No generic advice.
- Keep proposed edits minimal and composable — change the pipeline/nodes, not the `workflow.sh` control logic, unless a real defect is found there.
- Do not apply edits without user approval.
- Distinguish workflow-level improvements (bake into the skill) from project-specific one-offs (do not).
