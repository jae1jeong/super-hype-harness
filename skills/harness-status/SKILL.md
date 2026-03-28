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
4. Read `docs/harness/sprint-log.md` for centralized sprint history
5. Display formatted progress

## Output Format

```
[project name]
Phase: [brainstorm|review|implementation|qa|ship] ([detail])

Sprint | Status    | Score | Retries | Duration | Notes
-------|-----------|-------|---------|----------|------
  1    | PASS      |  8/10 |    0    |   12m    |
  2    | PASS      |  7/10 |    1    |   23m    | 1 retry
  3    | ESCALATED |  3/10 |    3    |   45m    | pivot: changed approach to X
  4    | IN_PROGRESS| -    |    -    |    -     |
  5    | PENDING   |  -    |    -    |    -     |

auto-resume: [ON|OFF]
last-commit: [SHA]
```

If --verbose: also show latest evaluator feedback summary for each completed sprint.
