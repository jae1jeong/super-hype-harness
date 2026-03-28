---
name: harness-qa
description: Final QA is now handled by the Evaluator as a single pass at the end of each build round. This skill is kept for standalone QA invocation.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Harness QA

> In the V2 architecture, QA is integrated into the Evaluator's single-pass assessment at the end of each build round. This skill exists for standalone QA invocation outside the pipeline.

## When to Use

- Standalone QA outside the harness pipeline
- Additional QA pass requested by user after pipeline completion

## Process

Same as the Evaluator's process — see `skills/harness-evaluator/SKILL.md`.

1. Read config for app_type
2. Read spec for user journey
3. For web apps: agent-browser is REQUIRED
4. Screenshot and study every page
5. Test all user flows from the spec
6. Reference comparison if applicable

## Output

Write to `docs/harness/qa-report.md`:

```markdown
# QA Report

## App Type: [web|cli|library]
## Overall: [PASS|FAIL]

## Scenarios Tested
1. [scenario]: [PASS|FAIL] - [details]

## Reference Comparison (if applicable)
- Overall alignment: [assessment]
- Matching: [list]
- Gaps: [list]

## Bugs Found and Fixed
1. [description] - [fix] - [verified: yes/no]

## Remaining Issues
- [unfixed issues]
```

## Handoff

Update state.md: `next_role: ship`
