# Manifests Checklist

## package.json

**Report:**
- `"*"` or `"latest"` dependency versions.
- Same package in both `dependencies` and `devDependencies`.
- Scripts referencing tools not declared in `devDependencies`.

## Cargo.toml

**Report:**
- Wildcard version requirements (`*`).
- Git dependencies without `rev` or `tag` pin.
- Dependencies in the wrong section (`[dependencies]` vs `[dev-dependencies]` vs `[build-dependencies]`).
- Non-additive feature flags that break downstream users.

## Do NOT report

- Version range preferences (`^` vs `~`) unless it creates a concrete risk.
- Dependency ordering within a section.
- Missing optional metadata fields.
