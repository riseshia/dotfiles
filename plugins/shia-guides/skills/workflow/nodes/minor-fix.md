# State: minor-fix

Role: apply the nits from `validate`. A worker (`workers/minor-fix.txt`, run via `claude -p`) edits and re-verifies in a fresh process. Do NOT fix inline. The items to fix are in `.workflow/feedback.md` (written by `validate`).

Steps:

1. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
2. Route on the returned `RESULT`:
   - `FIXED` -> delete `.workflow/feedback.md`, then `bash <skill-dir>/workflow.sh fire recheck`.
   - `EXCEEDED` -> overwrite `.workflow/feedback.md` with the escalation reason, then `bash <skill-dir>/workflow.sh fire rework` (shared guard, max 5).
