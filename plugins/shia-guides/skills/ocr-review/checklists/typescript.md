# TypeScript / JavaScript / React Checklist

## Report

- Unsafe `any` or type assertion (`as`) hiding real type uncertainty in critical paths.
- Null/undefined mishandling around destructuring, optional chaining, and property access.
- React hook rule violations: hooks inside conditions, loops, or callbacks.
- Missing `useEffect` cleanup (e.g., subscriptions, timers, abort controllers not cleaned up).
- Wrong `useEffect` dependency list causing stale closures or infinite re-renders.
- Side effects during render (mutations, subscriptions, API calls outside `useEffect`).
- XSS: `dangerouslySetInnerHTML`, unescaped user input, `eval()`, `Function()`, `document.write()`.
- Async error handling gaps: missing `.catch()`, unhandled promise rejection, missing abort/cancellation.
- Sequential `await` where `Promise.all` / `Promise.allSettled` is clearly intended.

## Do NOT report

- `==` vs `===` unless the loose comparison creates a real type-coercion bug.
- `var` unless it creates an actual scoping bug (not just style preference).
- Nested ternaries unless they genuinely obscure control flow for the reader.
- Missing TypeScript strict-mode flags or tsconfig preferences.
- ESLint/Prettier-level lints.
