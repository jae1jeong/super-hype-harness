---
name: harness-status
description: Display current harness pipeline progress. Shows sprint scores, phase, and auto-resume status.
argument-hint: [--verbose]
allowed-tools: [Read, Glob, Grep]
---

# Harness Status

User-invoked skill (`/harness-status`) that displays pipeline progress.

## Process

1. Check if `docs/harness/state.md` exists. If not: "No harness pipeline running."
2. Read state.md for current phase, sprint, and project name
3. Read config.md for auto_resume setting
4. Scan `docs/harness/feedback/` for sprint scores
5. Display formatted progress

## Output Format

```
[project name]
Phase: [brainstorm|review|implementation|qa|ship] ([detail])

Sprint 1: [PASS|FAIL|IN_PROGRESS|PENDING] [score]
Sprint 2: [PASS|FAIL|IN_PROGRESS|PENDING] [score]
...

auto-resume: [ON|OFF]
last-commit: [SHA]
```

If --verbose: also show latest evaluator feedback summary for each completed sprint.
