---
name: stepback
description: Stop and re-align when the conversation has drifted — re-read the actual request, surface and check assumptions, name where you went off, and re-answer short. Manual reset the user triggers with /stepback (append `deep` to also re-read the source material or spawn a fresh critic).
user_invocable: true
arguments: mode
---

## When to use

The user invokes this (`/stepback`, or `/stepback deep`) when the conversation has gone off the rails — you misread the ask, asserted something you never checked, buried the point in a wall of text, or did more than was asked. This is a manual reset; do not auto-invoke it.

## Your task

Stop the current line of work. Do not defend or continue it. Run this routine, then answer in Korean.

1. **Re-read the request, literally.** Go back to the user's most recent actual ask — not your interpretation of it. Quote its core in one line.
2. **List your assumptions.** Every assumption the drifted work rested on, one line each. Mark each:
   - `확인` — you checked a file / command / source **this session**.
   - `미확인` — you inferred it. (Your own confidence is not a check.)
3. **Name the drift.** Which happened: asserted a `미확인` as fact / misread the ask / over-produced a wall / did more than asked / other.
4. **Re-answer, short.** Lead with the conclusion in one line. Put any load-bearing assumption on the first line as `짐작: …`. Cut everything that wasn't asked for.

### `deep` mode

If the argument is `deep`, do steps 1–3, then — **before** re-answering — break the introspection blind spot (you can't see what you don't realize you assumed):

- **Re-ground on the input, not your memory:** re-read the actual files / links / docs the request refers to (the source, not your recollection of it). Fix any `미확인` that turns out wrong.
- **Or bring fresh eyes:** spawn a subagent (`model: sonnet`) told to *refute* your last answer against the request and its source material. Keep only what survives.

Then re-answer as in step 4.

## Output format (Korean)

```
## 다시 읽은 요청
[한 줄]

## 짐작
- 확인   [assumption]  (src: …)
- 미확인 [assumption]

## 어디서 샜나
[한 줄]

## 다시
[짐작: … — 있으면]
[짧게 고친 답]
```
