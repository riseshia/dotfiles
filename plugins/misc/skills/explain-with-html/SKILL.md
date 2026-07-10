---
name: explain-with-html
description: Explain a topic as a single, readable, self-contained HTML file that the user opens in a browser. Use when the user runs /explain-with-html, or asks to have something explained "as HTML", "in a browser", or with a visual/diagram-heavy write-up. The topic is optional — infer it from the recent conversation and confirm before generating. Use mermaid.js for diagrams when they help.
argument-hint: "[topic]"
---

# Explain with HTML

Explain a topic as a **single, readable, self-contained HTML file** the user opens in a browser.
Use it when structure, diagrams, and emphasis convey understanding better than plain prose does.

## 1. Fix the topic

- **If an argument is given**, use it as the topic.
- **If not**, infer what the user has been trying to understand from recent context and confirm
  with a one-line question (`"Shall I explain X?"`) **before** proceeding. If several topics fit,
  propose the most likely one (optionally list the others).
- Don't generate on a guess alone. The topic must be settled before moving on.

## 2. Model the reader & design the explanation

Before writing, decide **whose gap you are closing**. This is what drives quality.

- **Model the reader.** The reader is usually the user in this conversation. From the transcript,
  infer what they already know (terms used correctly, systems they built or referenced) and where
  they are actually stuck (the question asked, the misconception behind it, the parts they re-ask).
  Use what they know as stepping stones; don't re-teach it.
- **Aim at one gap.** Not an encyclopedia entry — close the specific gap behind "why are they
  asking this now".
- **Design principles**: motivation before mechanism; known → unknown; big picture → detail;
  concrete/analogy first → abstract later. Refute misconceptions head-on, then give the correct
  model. One concept at a time.

See `reference/explaining-clearly.md` for the full method and rationale.

## 3. Generate the HTML

Turn the design above into an easy-to-follow HTML document.

- **Single file, self-contained.** Inline the CSS in `<style>`. External assets via CDN only (e.g. mermaid).
- **Dark/light both.** Auto-switch via `prefers-color-scheme`.
- **Readability first.** Constrained body width, generous line height, clear sections, a summary box,
  callout/warning boxes, step lists — whatever aids understanding, as the topic calls for.
- **Language** of the explanation follows the conversation language (Korean by default).
- **Use mermaid.js when a diagram helps** (flow/sequence/state). Load it via CDN in a
  `<script type="module">` and match the theme to the OS color scheme. Put labels inside the diagram,
  and place the diagram right next to the text it explains. Omit it when it doesn't help.

Style is up to you. If you want a reference for tone and components, open `reference/template.html` —
**you are not obligated to follow it**; build what fits the topic.

Save under this session's **scratchpad directory** (the path given in the environment). Name the file
with a slug reflecting the topic (e.g. `dynamodb-lock.html`).

## 4. Open it

After generating, open it on macOS:

```bash
open "<scratchpad>/<slug>.html"
```

Then tell the user the file path and a line or two on what you explained and how.
