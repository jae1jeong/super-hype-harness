---
name: harness-resume
description: Resume harness pipeline from saved state. Reads state.md and re-enters the role loop.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Harness Resume

Invoked by `/harness --resume`. Reads saved state and re-enters the role loop.

## Process

### 1. Safety Checks
- Read `docs/harness/state.md`
- If status is not `paused`: error "재개할 파이프라인이 없습니다."

### 2. Rate Limit Check
- If still rate limited: increment resume_attempts, schedule next via `at`, exit
- If not rate limited: reset resume_attempts to 0

### 3. Resume
- Update state.md: `status: running`, `resume_attempts: 0`
- Read `next_role` from state.md
- Announce: "파이프라인 재개. 현재 역할: [next_role], 라운드: [current_round]"
- Read the corresponding SKILL.md and follow its instructions
- Continue the role loop after completion
