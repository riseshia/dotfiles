# Rust Conventions

Coding conventions and best practices for Rust projects.

## Coding Guidelines

### Import (`use`) Statements

Default: don't add `use` for std or external-crate items unless asked; same-crate imports follow the rules below.

- Global `use` statements at the top of files are discouraged (except in `mod.rs` and `lib.rs`)
- Avoid `use` for structs and enums; write full paths (e.g., `std::collections::HashMap` instead of `use std::collections::HashMap`)
- When importing traits, place the `use` statement in the most specific scope where they're needed

### Using `crate::` reference

- Reference same-crate items with `crate::`, even in the same module (e.g., `crate::utils::helper_function()`)

## Development Practices

- Must pass cargo clippy before commit
