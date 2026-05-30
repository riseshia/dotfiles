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

## Common principles

- Simplicity: prefer simple, straightforward solutions over complex ones.
- Consistency: follow the existing style of the codebase you're working in, or the conventions of the language if no style exists.
- Readability: prioritize code that is easy to read and understand, even if it's not the most concise or performant solution.
- Grepability: write code that is easy to search for and navigate, using clear naming and structure.
- Comments: write comments that explain *why*, not *what*.
  - Do write: non-obvious decisions and trade-offs, context that won't be recoverable from the code later, and explanations for code that isn't simple to grasp at a glance.
  - Don't write: comments restating what the code already makes obvious, or notes that are only relevant while the work is in progress (e.g. "changed this", "TODO for this PR", referencing the task at hand).

## Language references

| Language / context | Detect by | Reference to read |
|---|---|---|
| Ruby | `.rb`, `Gemfile`, RSpec | `reference/ruby.md` |
| Ruby on Rails | Rails project (`config/application.rb`, ActiveRecord, migrations) | `reference/rails.md` **and** `reference/ruby.md` |
| Rust | `.rs`, `Cargo.toml` | `reference/rust.md` |
| Terraform | `.tf`, `.tfvars`, HCL | `reference/terraform.md` |
| TypeScript / React | `.ts`, `.tsx`, React | `reference/typescript.md` |

For Rails work, apply both the Ruby and Rails references (Rails conventions build on top of the Ruby ones).
