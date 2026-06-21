# Rust Checklist

## Report

- `unwrap()`, `expect()`, `panic!()`, `todo!()`, `unimplemented!()` in recoverable paths (not tests or known-safe invariants).
- Incorrect lifetime or ownership assumptions that will cause compile errors or unsoundness.
- `unsafe` blocks without narrow scope or without a `// SAFETY:` rationale.
- Holding `Mutex`/`RwLock` guards across `.await` points.
- Dropped `JoinHandle` where task failure or shutdown ordering matters.
- Cancellation-unsafe code: partial writes or uncommitted transactions in async contexts.
- Integer conversion (`as` casts), slice indexing, or UTF-8 boundary issues that can panic.
- Unnecessary `clone()` where a borrow is clearly sufficient and simpler.

## Do NOT report

- `clone()` in non-hot-path code where the alternative is significantly more complex.
- `unwrap()` in tests or immediately after a check that guarantees `Some`/`Ok`.
- Clippy-level lints (the user has clippy for that).
- Missing `#[must_use]` or documentation attributes.
