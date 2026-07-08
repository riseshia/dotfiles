# State: retrospect

Role: run the session-level retrospective before the run is torn down, while `.workflow/` (`history.log`, counters, `plan.md`, `feedback.md`) still exists — the retro reads it.

Steps:

1. Invoke the **`shia-guides:workflow-retro`** skill. It reconstructs the timeline from `.workflow/history.log`, identifies friction, and proposes concrete edits to the workflow's `pipeline` / `nodes/*.md` / `workers/*.txt` surfaces.
2. Relay its output (timeline, friction, proposed changes, recommendation) to the user. Apply edits only on approval, per that skill's own constraints — including distinguishing workflow-level fixes (bake into the skill) from project-specific one-offs (do not).

Fire: `bash <skill-dir>/workflow.sh fire submit` -> `done`.

After `done`, offer `bash <skill-dir>/workflow.sh abort` to clear `.workflow/` state once the user is satisfied. (Note: `fire exit` -> `exited` preserves `.workflow/` and the branch for human pickup; `abort` discards everything.) Run `abort` only after the retro is done — it deletes the `history.log` the retro depends on.
