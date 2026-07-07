# State: validate

Role: **judge the work** — independently, on a clean state. A worker (`workers/validate.txt`, run via `claude -p`) runs the verification and reviews the diff in a fresh process and returns a verdict. Do NOT validate inline; you read only the verdict.

Steps:

1. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
2. Route on the returned `VERDICT`:
   - `CLEAN` -> `bash <skill-dir>/workflow.sh fire recheck`.
   - `MINOR` -> overwrite `.workflow/feedback.md` with the listed items (markdown bullets, one per line), then `bash <skill-dir>/workflow.sh fire minor "<one-line verdict summary>"`.
   - `SIGNIFICANT` -> overwrite `.workflow/feedback.md` with the reason + required changes (markdown bullets), then `bash <skill-dir>/workflow.sh fire rework "<one-line verdict summary>"` (shared `rework` guard; if exhausted the CLI rejects it — ask the user: ship what works, or `fire exit`).

When a loop-back's feedback redefines the plan's **contract** (approach/scope/interface) rather than just fixing a defect, update `.workflow/plan.md` to match as you write `.workflow/feedback.md` — otherwise the next `validate` compares the change against a stale plan and re-flags it as divergence.
