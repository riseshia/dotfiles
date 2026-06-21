# RSpec Checklist

## Report

- Test description does not match what is actually asserted.
- Brittle expectations tied to incidental implementation details (e.g., exact SQL, internal method call order).
- Excessive mocking that hides integration failures -- mocking the thing you are testing.
- Missing negative/boundary case when the changed production code has an obvious edge case.
- Time-dependent or order-dependent assertions that will be flaky.
- Factories or fixtures that bypass important model validations.

## Do NOT report

- Preference for `let` vs `let!` unless it causes a test-order dependency.
- `subject` vs explicit variable naming.
- Number of assertions per example unless it masks which assertion failed.
