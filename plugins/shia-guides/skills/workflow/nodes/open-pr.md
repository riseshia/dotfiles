# State: open-pr

Role: ship via a Draft PR — **this is where the human reviews the actual change**. A worker (`workers/open-pr.txt`, run via `claude -p`) does the git/`gh` work (following `shia-guides:draft-pr`) in a fresh process. Do NOT commit/push inline.

Steps:

1. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
2. Route on the report:
   - `PR: <url>` -> `bash <skill-dir>/workflow.sh set pr_url <url>`, then `bash <skill-dir>/workflow.sh fire submit`.
   - `FAILED: <reason>` -> **stop and report to the user**; do not fire `submit` on a change that did not ship. Resolve with the user, or `bash <skill-dir>/workflow.sh fire exit` to hand off with the branch intact.
