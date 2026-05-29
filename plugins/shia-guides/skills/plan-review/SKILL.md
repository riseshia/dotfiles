---
description: Plan review (apply feedback + ask questions)
userInvocable: true
arguments: filename
---

# Plan Review

## Workflow

1. Read the specified `{filename}` and grasp the overall picture of the plan
2. **Apply feedback**: Identify all comments prefixed with `XXX:` in the file and improve the plan accordingly
   - Questions or objections about the design → revise the design
   - Alternative proposals → evaluate and decide to adopt or reject
   - Additional requirements or constraints → incorporate into the plan
   - Missing perspectives → append
   - Remove `XXX:` comments that have been addressed. Leave difficult-to-resolve ones as `TODO:`
3. **Critical analysis**: Analyze the plan from the following perspectives and identify issues
   - **Ambiguous descriptions**: Areas where interpretation could diverge during implementation
   - **Overlooked considerations**: Edge cases, error handling, consistency with existing code, etc.
   - **Implicit assumptions**: Undocumented assumptions or dependencies
   - **Design alternatives**: Areas where multiple approaches exist but only one is chosen without justification
   - **Unclear scope**: Areas where the boundary of what is in/out of scope is vague
4. Insert each issue directly into the plan file at the relevant location in the format `AI-ASK: {question}`
   - Write questions specifically and concisely
   - Insert immediately after the relevant section (place close to the related context)
5. Present the user with a summary of changes made and questions added
   - If there are no `XXX:` comments and no questions, respond with "No unclear points in the plan. Ready for implementation." and finish

## Constraints

- **Never start implementation.** Only improve the plan and add questions.
- Do not edit or create code (only update the plan file).
- Preserve the original file's format and structure.
