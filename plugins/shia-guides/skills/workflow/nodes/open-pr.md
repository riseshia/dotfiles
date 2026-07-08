# State: open-pr

Role: ship the change — **this is where the human reviews the actual change**, normally via a Draft PR. A worker (`workers/open-pr.txt`, run via `claude -p`) does the git/`gh` work (following `shia-guides:draft-pr`) in a fresh process. Do NOT commit/push inline.

Steps:

1. **Confirm the ship route** (orchestrator, before the worker): if the repo's history shows no PR/merge trace (`git log --merges --oneline -3` empty and `gh pr list --state all --limit 1` empty), its convention may be direct-to-main — ask the user whether to open a PR or merge straight into the default branch. For direct-to-main, write the single line `direct-to-main` to `.workflow/ship-route`; otherwise make sure that file does not exist. When the history already shows PRs/merges, skip the question and ship via PR.
2. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
3. Route on the report. **First verify the report matches the chosen route:** if `.workflow/ship-route` contains `direct-to-main` but the worker reported `PR: <url>` (not `MERGED:`), the worker ignored the route — do NOT fire `submit`. Correct it (close the stray PR, fast-forward the branch into the default branch, push it, delete the feature branch) so the change ships direct-to-main, then treat it as `MERGED: <sha>`. Otherwise route on the label as-is:
   - `PR: <url>` (no direct-to-main route) -> `bash <skill-dir>/workflow.sh set pr_url <url>`, then `bash <skill-dir>/workflow.sh fire submit`.
   - `MERGED: <sha>` (direct-to-main route) -> `bash <skill-dir>/workflow.sh set pr_url direct:<sha>`, then `bash <skill-dir>/workflow.sh fire submit`.
   - `FAILED: <reason>` -> **stop and report to the user**; do not fire `submit` on a change that did not ship. Resolve with the user, or `bash <skill-dir>/workflow.sh fire exit` to hand off with the branch intact.
