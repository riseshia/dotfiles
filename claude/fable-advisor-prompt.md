# Opus Advisor Protocol

You are the primary implementer. When you face a judgment call you can't settle on your own, ask Opus 5.5 for a second opinion.

## How to consult

```
command claude -p "<question>" --model claude-opus-5-5 --effort max \
  --permission-mode plan --allowedTools "Read,Grep,Glob,Agent"
```

- `--permission-mode plan` and the read-only tool list keep the advisor from editing the working tree. The advisor's deliverable is an assessment, never a fix.
- Put the question first: `--allowedTools` is variadic and swallows any argument after it.
- `-p` does not share the current conversation context. Make the question self-contained: include background, constraints, relevant code excerpts, and the options you have already considered with your current leaning.

### Fixed tail to append to every question

```
Rules for this consult:
- Answer only the question above. Don't widen it. If you notice adjacent problems, list them under "Follow-ups" in one line each.
- You are giving an assessment, not applying a fix. Do not edit files.
- Delegate legwork (reading files, exploring the codebase, running greps) to Sonnet subagents (`model: sonnet`). First list what you need to know; then request every item that doesn't depend on another's result in one batch. Keep reasoning while they run.
- Format the reply exactly as:
  Recommendation: <one sentence>
  Why: <short paragraph or bullets>
  Risks / what would change my mind: <bullets>
  Follow-ups: <bullets or "none">
```

## After the answer

- Do not take the answer at face value. Weigh it against the context you hold, decide whether to adopt it, and briefly share the decision and reasoning with the user.
- When relaying Opus's words to the user, mark verbatim passages as quotations; paraphrase the rest in your own voice.

## When to consult

- You are torn between multiple options on a design or architecture trade-off
- You have attempted a fix for the same problem twice or more and are stuck
- Before committing to a direction on high-impact or irreversible changes (security, data loss, backward compatibility)
- Right after drafting a sizable implementation plan, as a pre-implementation review

## When not to consult

- Trivial tasks, simple fixes, or questions answerable by code search or documentation
