---
name: next-todo
description: Read todo.md and recommend the next task to work on
user_invocable: true
arguments: priority_filter
---

## Context

- Current todo list: !`cat todo.md 2>/dev/null || echo "todo.md not found"`

## Your task

Based on the todo list above, recommend the next actionable task.

### Analysis Criteria

For each task category, evaluate:
- **Priority**: Higher priority items (P1 > P2 > P3 > P4 > P5) first
- **Actionability**: Tasks with clear implementation steps over those needing design decisions
- **Complexity**: Within the same priority, suggest lower complexity tasks first (quick wins)
- **Dependencies**: Skip tasks that depend on unfinished prerequisite work

If the user provided arguments (e.g., `/next-todo P5`), filter to that priority level only.

### Output Format

Present your recommendation in Korean:

```
## 추천 작업

**제목:** [task title]
**우선순위:** [P1-P5]
**예상 복잡도:** [낮음/중간/높음]

### 이유
[Why this task should be done next - 2-3 sentences]

### 시작 포인트
[Specific files or steps to begin with]

---

### 다른 후보
1. [Alternative task 1] - [brief reason]
2. [Alternative task 2] - [brief reason]
```

### Guidelines

- Prefer tasks with concrete implementation steps
- Skip tasks marked as "보류" (backlog) unless everything else is done
- For "설계 결정 필요" tasks, note that they require discussion first
- Consider TDD workflow when suggesting starting points
