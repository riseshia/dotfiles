# General Checklist

## Report

- **Correctness:** logic errors, missing boundary checks, wrong conditionals, incorrect state transitions.
- **Security:** injection, XSS, unsafe deserialization, authz/authn mistakes, secret exposure, unsafe command construction.
- **Reliability:** missing error handling for operations that can fail, partial failure in multi-step operations.
- **Performance:** obvious N+1 queries, unbounded loops over large data, avoidable O(n^2), blocking operations in hot paths.
- **Concurrency:** race conditions, non-atomic check-then-act, unsafe shared mutable state.
- **Maintainability:** misleading names that will cause future bugs, duplicated complex logic with subtle divergence.

## Do NOT report

- Style preferences that do not affect correctness or maintainability.
- Missing tests unless the changed logic is non-trivial AND risk-bearing.
- "Could be improved" suggestions without a concrete correctness or safety benefit.
- Issues in code that was not changed in this diff.
- Non-functional elements: code comments, annotations, metadata, formatting.
