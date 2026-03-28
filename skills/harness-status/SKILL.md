---
name: harness-status
description: Display current harness pipeline progress. Shows sprint scores, phase, and pipeline health.
argument-hint: [--verbose]
allowed-tools: [Read, Glob, Grep]
---

# Harness Status

User-invoked skill (`/harness-status`) that displays pipeline progress.

## Process

1. Check if `docs/harness/state.md` exists. If not: "하네스 파이프라인이 실행 중이지 않습니다."
2. Read state.md for next_role, current_sprint, project name
3. Read config.md for settings
4. Read `docs/harness/sprint-log.md` for sprint history
5. Display formatted progress

## Output Format

```
[project name]
Role: [next_role] (current sprint: N/total)

Sprint | Status    | Score | Retries | Duration | Notes
-------|-----------|-------|---------|----------|------
  1    | PASS      |  8/10 |    0    |   12m    |
  2    | PASS      |  7/10 |    1    |   23m    | 1 retry
  3    | ESCALATED |  3/10 |    3    |   45m    | pivot: changed approach
  4    | IN_PROGRESS| -    |    -    |    -     |
  5    | PENDING   |  -    |    -    |    -     |

auto-resume: [ON|OFF]
references: [yes/no]
last-commit: [SHA]
```

If --verbose: also show latest evaluator feedback summary for each completed sprint.
