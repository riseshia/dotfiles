# State: implement

Role: a worker (`workers/implement.txt`, run via `claude -p`) implements the plan in a fresh process. Do NOT implement inline.

Steps:

1. Ensure a feature branch exists (never implement on `main`/`master`/`staging`). Name it per the draft-pr convention (`feature/…`, `fix/…`, `refactor/…`, `docs/…`, `chore/…`) and record it: `bash <skill-dir>/workflow.sh set branch <name>`. On re-entry (rework/continue), reuse the existing branch (`workflow.sh show` -> `branch`).
2. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
   (It reads `.workflow/feedback.md` if present — the reason for this rework/continue pass.)
3. Read the worker's report. **Do not blindly advance:**
   - **Completed** -> if a feedback loop drove this pass, delete `.workflow/feedback.md`; then `bash <skill-dir>/workflow.sh fire submit` -> `validate`.
   - **BLOCKED / divergence** -> usually a planning gap. Re-run the worker with the missing detail if you can resolve it; **escalate to the user inline** if a critical, uncovered requirement needs a human/product decision; or `bash <skill-dir>/workflow.sh fire exit` to hand off (branch + plan preserved). Don't force a blocker through the loop just to avoid asking.
