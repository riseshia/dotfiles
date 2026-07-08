# State: followup

Role: close-out and hand back to the human. Minimal — no project-management ceremony.

Steps:

1. **Report the result**: the PR URL, what was implemented, and the verification status. If earlier worker reports are no longer in your context, reconstruct from files: `workflow.sh show` (branch, pr_url), `.workflow/plan.md` (Goal/Steps), and `gh pr view` / `git log` on the branch.
2. **Capture stragglers**: list any out-of-scope items surfaced during the run as candidate follow-up tasks. Do not silently expand scope or act on them.
3. **Route to the retrospective.** The retro must not be skippable by accident — the machine makes it an explicit fork, so choose deliberately:
   - Ask the user whether to run a session-level retrospective now (default: yes — `.workflow/` is still intact, which the retro needs).
   - Fire `bash <skill-dir>/workflow.sh fire retro` -> `retrospect` to run it, or `bash <skill-dir>/workflow.sh fire skip "<why>"` -> `done` to bypass it (pass a one-line reason so the skip is visible in `history.log`).

Both `retro` and `skip` lead to `done`; there is no plain `submit` here. Do not fire `skip` without asking.

On the `skip` path, after `done` offer `bash <skill-dir>/workflow.sh abort` to clear `.workflow/` once the user is satisfied (`fire exit` -> `exited` preserves `.workflow/` and the branch for human pickup; `abort` discards everything). The `retro` path handles this hand-off in the `retrospect` node instead.
