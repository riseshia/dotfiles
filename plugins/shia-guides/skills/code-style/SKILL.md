---
name: code-style
description: riseshia's coding conventions. Use it always unless a project-specific convention (CLAUDE.md, style guides) exists.
user-invocable: false
version: 0.1.0
---

# Code Style

riseshia's coding conventions. **Project-specific conventions (the repo's CLAUDE.md, style guides, existing code) always take priority over this guidance.**

## How to use

Before writing or modifying code:

1. Identify the language of the file(s) you are working on.
2. If a matching reference below exists, **Read** that file and follow its conventions.
3. If no reference matches, fall back to the surrounding code's existing style.

## Language references

| Language / context | Detect by | Reference to read |
|---|---|---|
| Ruby | `.rb`, `Gemfile`, RSpec | `reference/ruby.md` |
| Ruby on Rails | Rails project (`config/application.rb`, ActiveRecord, migrations) | `reference/rails.md` **and** `reference/ruby.md` |
| Rust | `.rs`, `Cargo.toml` | `reference/rust.md` |
| Terraform | `.tf`, `.tfvars`, HCL | `reference/terraform.md` |
| TypeScript / React | `.ts`, `.tsx`, React | `reference/typescript.md` |

For Rails work, apply both the Ruby and Rails references (Rails conventions build on top of the Ruby ones).
