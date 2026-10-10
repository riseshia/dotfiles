---
name: code-style
description: riseshia's coding conventions. Use it always unless a project-specific convention (CLAUDE.md, style guides) exists.
user-invocable: false
version: 0.4.0
---

# Code Style

riseshia's coding conventions. **Project-specific conventions (the repo's CLAUDE.md, style guides, existing code) always take priority over this guidance.**

## How to use

Before writing or modifying code:

1. Identify the language of the file(s) you are working on.
2. If a matching reference below exists, **Read** that file and follow its conventions.
3. If no reference matches, fall back to the surrounding code's existing style.

## Common principles

- Simplicity: prefer simple, straightforward solutions over complex ones. No abstraction for single-use code, no configurability that was not asked for, no error handling for scenarios that cannot occur.
- Scope of change: every changed line traces back to the request. Remove the imports, variables, and functions that *your* change orphaned; leave pre-existing dead code alone and mention it instead.
- Consistency: follow the existing style of the codebase you're working in, or the conventions of the language if no style exists.
- Readability: prioritize code that is easy to read and understand, even if it's not the most concise or performant solution.
- Grepability: write code that is easy to search for and navigate, using clear naming and structure.
- Information layers: code expresses **How**, tests express **What**, the commit log records **Why**, and code comments record **Why not**. Put each piece of information where it belongs.
- Comments: write comments that explain *why* and *why not*, not *what* — see Code Comments below.

## Code Comments

Comments must not repeat what the code already expresses. Use comments for explaining **why** something is done, or to provide context not obvious from the code itself.

**Default to no comment.** Write one only when a reader would otherwise make a wrong change. Before keeping a comment, apply two tests:

- Delete test: if the comment were deleted, would a future reader lose anything they cannot recover from the code in a few seconds? If not, delete it.
- Cold-reader test: the reader has only the repository — not this conversation, the plan, the PR, or the previous version of the code. Would they understand every word? If the comment relies on session context (e.g. "the new approach", "as discussed", "instead of the old X", "per the request", invented labels, step or section numbers such as "Step 3" or "Section 2.1" that point into a plan or spec the reader does not have), rewrite it in self-contained terms or delete it.

**When to comment:**

- To explain why a particular approach or workaround was chosen
- To record why an obvious-looking alternative was *not* taken (the why not)
- To clarify intent when the code could be misread or misunderstood
- To provide context from external systems, specs, or requirements
- To document assumptions, edge cases, or limitations

**When not to comment:**

- Do not duplicate function or variable names in plain English
- Do not leave stale comments that contradict the code

## Documentation

Code is the source of truth.

- Do not maintain design docs that duplicate what the code expresses — keeping documents consistent with each other is harder than keeping code consistent.
- Write code clean enough that no document is needed to explain the How.
- The durable Why lives in commit messages and PR descriptions; the Why not in code comments. Keep a separate document only for decisions too large for those (ADR-style), version-controlled alongside the code.
- Plan or design docs used to produce a change are throwaway inputs, not maintained artifacts.

## Language references

| Language / context | Detect by | Reference to read |
|---|---|---|
| Ruby | `.rb`, `Gemfile`, RSpec | `reference/ruby.md` |
| Ruby on Rails | Rails project (`config/application.rb`, ActiveRecord, migrations) | `reference/rails.md` **and** `reference/ruby.md` |
| Rust | `.rs`, `Cargo.toml` | `reference/rust.md` |
| Terraform | `.tf`, `.tfvars`, HCL | `reference/terraform.md` |
| TypeScript / React | `.ts`, `.tsx`, React | `reference/typescript.md` |

For Rails work, apply both the Ruby and Rails references (Rails conventions build on top of the Ruby ones).
