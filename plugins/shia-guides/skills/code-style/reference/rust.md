# Rust Conventions

Coding conventions and best practices for Rust projects.

## Coding Guidelines

### Import (`use`) Statements

__Default: Don't add `use` for std or external-crate items unless explicitly requested by humans; same-crate imports follow the rules below__

- Global `use` statements at the top of files are discouraged (except in `mod.rs` and `lib.rs`)
- Avoid `use` for structs and enums - ALWAYS prefer full paths (e.g., `std::collections::HashMap` instead of `use std::collections::HashMap`)
- `use` is allowed for frequently used modules within the same crate (e.g., `use crate::config`)
- When importing traits, place the `use` statement in the most specific scope where they're needed

### Using `crate::` reference

- Always use `crate::` for referencing items within the same crate, even in the same module (e.g., `crate::utils::helper_function()`)

## Development Practices

- Must pass cargo clippy before commit
