# Rails Checklist

## Report

- N+1 queries: associations accessed in loops without `includes`/`preload`/`eager_load`.
- Missing `transaction` around multi-step writes that must be atomic.
- Callback side effects (e.g., `after_save` triggering external calls) that can fail silently or run unexpectedly.
- Validations without corresponding database constraints for uniqueness or NOT NULL.
- Raw SQL with string interpolation instead of parameterized queries.
- Missing or incorrect strong parameters.
- Missing authorization checks in controller/service changes.
- Background jobs that are not idempotent or retry-safe.
- Migration safety: adding columns with defaults on large tables, adding NOT NULL without a default, non-concurrent index creation on large tables.

## Do NOT report

- Callback usage itself -- only problematic side effects.
- Missing indexes unless the query pattern is visible in the changed code.
- `has_many`/`belongs_to` declarations unless the foreign key or dependent behavior is incorrect.
