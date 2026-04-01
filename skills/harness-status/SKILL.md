---
name: harness-status
description: Display current harness pipeline progress. Shows build rounds, scores, and pipeline health.
argument-hint: [--verbose] [--log] [--tests]
allowed-tools: [Read, Glob, Grep]
---

# Harness Status

User-invoked skill (`/harness-status`) that displays pipeline progress.

## Process

1. Check if `docs/harness/state.md` exists. If not: "하네스 파이프라인이 실행 중이지 않습니다."
2. Read state.md for next_role, current_round, project name
3. Read `docs/harness/build-log.md` for round history
4. If `--log` or `--verbose`: Read `docs/harness/pipeline-log.md` for detailed agent activity
5. Display formatted progress

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

If `--verbose`: show latest evaluator feedback summary.

If `--log`: show pipeline activity log:
```
Pipeline Activity Log (최근 20건):

Timestamp           | Phase      | Actor       | Event     | Skills Used              | Duration | Details
--------------------|------------|-------------|-----------|--------------------------|----------|--------
2026-04-01 10:00:00 | brainstorm | orchestrator| dispatch  | -                        | -        | office-hours config
2026-04-01 10:32:00 | brainstorm | brainstorm  | complete  | office-hours             | 32m      | spec 생성 완료
2026-04-01 10:32:01 | review     | orchestrator| dispatch  | -                        | -        | ceo_review agent
...

Skills Summary:
  generator: frontend-design, vercel-react-best-practices
  evaluator: agent-browser (×3 rounds), web-design-guidelines
  brainstorm: office-hours
  Total pipeline duration: 4h 23m
```

If `--tests`: show test case execution summary from latest `docs/harness/feedback/round-N-test-summary.md`:
```
Test Cases (Round 3):
  Total: 127 | Executed: 119 | PASS: 108 | FAIL: 11 | Untested: 8
  
  Category     | Generated | Executed | PASS | FAIL
  -------------|-----------|----------|------|-----
  Component    |    42     |    40    |  37  |   3
  E2E          |    28     |    28    |  25  |   3
  Edge Case    |    35     |    31    |  28  |   3
  Performance  |    22     |    20    |  18  |   2

  Adversarial additions: 12 (4 caught real issues)
```
