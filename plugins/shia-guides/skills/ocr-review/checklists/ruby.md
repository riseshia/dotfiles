# Ruby Checklist

## Report

- Nil handling likely to cause `NoMethodError` in production paths.
- Swallowed errors hiding failures, over-broad `rescue` catching unrelated exceptions.
- Enumerable misuse causing unnecessary allocations or O(n^2) (e.g., `select` + `first` instead of `find`).
- Thread-safety issues around class variables, globals, memoization with `||=` on shared mutable state.
- Shell command construction via string interpolation (`system("cmd #{user_input}")`).
- SQL construction via string interpolation.
- `YAML.load` or `Marshal.load` on untrusted input.
- Timezone issues: `Time.now` vs `Time.current`, `Date.today` vs `Date.current` in timezone-aware apps.

## Do NOT report

- Method length or complexity metrics without a concrete bug risk.
- `rescue => e` when the error is logged/re-raised appropriately.
- Style preferences for blocks, string literals, or naming that match the surrounding code's conventions.
- Rubocop-level lints (the user has rubocop for that).
