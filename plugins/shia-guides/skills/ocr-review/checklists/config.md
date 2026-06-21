# YAML / JSON / Config Checklist

## Report

- Duplicate or conflicting keys (YAML silently takes the last value).
- Secrets or credentials committed in plaintext.
- Wildcard or unpinned versions where reproducibility matters.
- Environment-specific values hardcoded in shared config.
- CI workflow permissions that are broader than necessary (e.g., `permissions: write-all`).
- Unpinned third-party GitHub Actions (use commit SHA, not branch/tag).

## Do NOT report

- Formatting or key ordering preferences.
- Comment style in YAML.
- JSON trailing comma issues (the parser will catch these).
