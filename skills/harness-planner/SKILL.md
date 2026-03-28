---
name: harness-planner
description: Decomposes a reviewed spec into executable sprints with testable completion criteria.
allowed-tools: [Read, Write, Glob, Grep]
---

# Harness Planner

Converts a reviewed spec into a sprint plan. Each sprint = one feature at a time.

> "The planner took a simple 1-4 sentence prompt and expanded it into a full product spec... a 16-feature spec spread across ten sprints." — Anthropic

## Input

Read the spec path from `docs/harness/state.md` → `spec` field.
If references exist (`has_references: true`), read `docs/harness/references/index.md` and reference images.

## Process

1. Analyze the spec for feature scope, tech stack, and dependencies
2. If references exist: plan sprints to progressively match the reference (layout first, then features, then polish)
3. Decompose into 5-15 sprints (typical range)
4. Order by dependency: infrastructure first, features second, polish last
5. Each sprint should be completable in one Generator pass

## Sprint Structure

For each sprint:

### Goal
One sentence describing what this sprint delivers.

### Done Definition
Testable checklist items. Each must be verifiable:
- Build/test commands with expected output
- API endpoints with expected responses
- UI elements that should be visible/interactive

### Verification Method
How to verify each Done item:
- `build`: run build command, check exit code 0
- `test`: run test command, check all pass
- `api`: curl endpoint, check response
- `browser`: navigate to URL, check element exists
- `cli`: run command, check output

### Dependencies
Which previous sprints must be complete.

## Output

Write to `docs/harness/plans/YYYY-MM-DD-plan.md`:

```markdown
# Sprint Plan: [Project Name]

## Overview
- Total sprints: N
- Tech stack: [...]
- Dependency graph: Sprint 1 → Sprint 2 → ...

## Sprint 1: [Title]
### Goal
[one sentence]
### Done Definition
- [ ] [testable criterion 1]
- [ ] [testable criterion 2]
### Verification Method
- [method for each criterion]
### Dependencies
- None (first sprint)

## Sprint 2: [Title]
...
```

## Guidelines

- Sprint 1 is ALWAYS project scaffolding + dev environment
- Last sprint is ALWAYS polish + final integration
- Each sprint should produce a working (if incomplete) app
- Prefer small sprints over large ones

Git commit the plan file.

## Handoff

After writing the plan:
1. Update `docs/harness/state.md`:
   - `plan: docs/harness/plans/YYYY-MM-DD-plan.md`
   - `total_sprints: N`
   - `current_sprint: 1`
   - `next_role: generator`
2. Announce: "Plan 작성 완료 (N sprints). state.md에 따라 generator 단계로 진행합니다."
