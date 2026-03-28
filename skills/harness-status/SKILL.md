---
name: harness-status
description: Display current harness pipeline progress. Shows build rounds, scores, and pipeline health.
argument-hint: [--verbose]
allowed-tools: [Read, Glob, Grep]
---

# Harness Status

User-invoked skill (`/harness-status`) that displays pipeline progress.

## Process

1. Check if `docs/harness/state.md` exists. If not: "하네스 파이프라인이 실행 중이지 않습니다."
2. Read state.md for next_role, current_round, project name
3. Read `docs/harness/build-log.md` for round history
4. Display formatted progress

## Output Format

```
[project name]
Role: [next_role] | Round: [current_round]

Round | Phase | Score | Duration | Notes
------|-------|-------|----------|------
  1   | Build |   -   | 2h 7m   |
  1   | QA    | 6/10  | 8.8m    | 12 criteria failed
  2   | Build |   -   | 1h 2m   |
  2   | QA    | 8/10  | 6.8m    | 3 criteria failed
  3   | Build |   -   | 10.9m   |
  3   | QA    | 9/10  | 9.6m    | PASS

auto-resume: [ON|OFF]
references: [yes/no]
last-commit: [SHA]
```

If --verbose: show latest evaluator feedback summary.
