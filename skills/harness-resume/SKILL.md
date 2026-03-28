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
- Compare `last_commit` in state.md with current `git log --oneline -1` HEAD
  - Mismatch: warn "레포지토리 상태가 일시정지 이후 변경되었습니다."

### 2. Rate Limit Check (Exponential Backoff)
- Read `resume_attempts` from state.md
- If still rate limited:
  - Increment resume_attempts
  - Calculate backoff: 30min × 2^(attempts - 1), max 2 hours
  - Schedule next resume via `at` command
  - Update state.md with new resume_after and resume_attempts
  - Exit

### 3. Resume
- Update state.md: `status: running`, `resume_attempts: 0`
- Read `next_role` from state.md
- Announce: "파이프라인 재개. 현재 역할: [next_role]"
- Read the corresponding SKILL.md and follow its instructions:
  - `brainstorm` → `skills/harness-brainstorm/SKILL.md`
  - `review` → review logic in `skills/harness/SKILL.md`
  - `planner` → `skills/harness-planner/SKILL.md`
  - `generator` → `skills/harness-generator/SKILL.md`
  - `evaluator` → `skills/harness-evaluator/SKILL.md`
  - `qa` → `skills/harness-qa/SKILL.md`
  - `ship` → ship logic in `skills/harness/SKILL.md`
- After completing that role, continue the role loop (read state.md → next role → follow)
