# State: followup

Role: close-out and hand back to the human. Minimal — no project-management ceremony.

Steps:

1. **Report the result**: the PR URL, what was implemented, and the verification status. If earlier worker reports are no longer in your context, reconstruct from files: `workflow.sh show` (branch, pr_url), `.workflow/plan.md` (Goal/Steps), and `gh pr view` / `git log` on the branch.
2. **Capture stragglers**: list any out-of-scope items surfaced during the run as candidate follow-up tasks. Do not silently expand scope or act on them.
3. Suggest running `shia-guides:workflow-retro` for a session-level retrospective.

Fire: `bash <skill-dir>/workflow.sh fire submit` -> `done`.

After `done`, offer `bash <skill-dir>/workflow.sh abort` to clear `.workflow/` state once the user is satisfied. (Note: `fire exit` -> `exited` preserves `.workflow/` and the branch for human pickup; `abort` discards everything.)
