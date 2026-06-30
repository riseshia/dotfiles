# State: recheck

Role: **decide to ship.** A confidence gate on the integrated final state — not a place to find new design issues (those belong to `validate`). A worker (`workers/recheck.txt`, run via `claude -p`) re-verifies in a fresh process and returns a result. Do NOT verify inline.

Steps:

1. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
2. Route on the returned `RESULT`:
   - `READY` -> `bash <skill-dir>/workflow.sh fire pr`.
   - `NOT-READY` -> write the reason to `.workflow/feedback.md`, then `bash <skill-dir>/workflow.sh fire continue`. Last-chance loop (max 1): a problem that escaped `validate` reappeared. If `continue` is exhausted, do not ship — `bash <skill-dir>/workflow.sh fire exit`.

The only ship path is a Draft PR — the human reviews the actual change there.
