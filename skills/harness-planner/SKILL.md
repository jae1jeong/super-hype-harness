---
name: harness-planner
description: Decomposes a reviewed spec into executable sprints with testable completion criteria. Used internally by the harness pipeline after review phase.
allowed-tools: [Read, Write, Glob, Grep]
---

# Harness Planner

Decomposes a reviewed spec into a sprint plan. Runs as an Agent subprocess.

## Input

Read the spec from `docs/harness/specs/` (most recent file matching `YYYY-MM-DD-*-spec.md`).

## Process

1. Analyze the spec for feature scope, tech stack, and dependencies
2. Decompose into 5-15 sprints (typical range)
3. Order sprints by dependency: infrastructure first, features second, polish last
4. Each sprint should be completable in one Generator session

## Sprint Structure

For each sprint, define:

### Goal
One sentence describing what this sprint delivers.

### Done Definition
Testable checklist items. Each item must be verifiable by the Evaluator:
- Build/test commands with expected output
- API endpoints with expected responses
- UI elements that should be visible/interactive

### Verification Method
How the Evaluator should verify each Done item:
- `build`: run build command, check exit code 0
- `test`: run test command, check all pass
- `api`: curl endpoint, check response
- `browser`: navigate to URL, check element exists (for web apps)
- `cli`: run command, check output

### Dependencies
Which previous sprints must be complete.

## Output Format

Write to `docs/harness/plans/YYYY-MM-DD-plan.md`:

```markdown
# Sprint Plan: [Project Name]

## Overview
- Total sprints: N
- Tech stack: [...]
- Dependency graph: Sprint 1 -> Sprint 2 -> ...

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
- If a feature is complex, split across multiple sprints

Git commit the plan file.
