---
name: harness-resume
description: Internal resume logic for harness pipeline. Restores state from docs/harness/state.md and continues from interruption point. Not user-facing.
allowed-tools: [Agent, Read, Write, Edit, Bash, Glob, Grep, TaskCreate, TaskUpdate]
---

# Harness Resume

Internal skill invoked by `/harness --resume`. NOT a standalone slash command.

## Process

### 1. Safety Checks
- Read `docs/harness/state.md`
- If status is not `paused` or `self_resetting`: error "No paused pipeline to resume"
- Compare `last_commit` in state.md with current `git log --oneline -1` HEAD
  - Mismatch: warn "Repository state changed since pause. Manual changes detected."
- Check lock file `docs/harness/.lock`:
  - If lock exists and PID is still alive: error "Another harness instance is running"
  - If lock exists but PID is dead (stale): remove lock and proceed
  - If no lock: proceed

### 2. Rate Limit Check (Exponential Backoff)
- Read `resume_attempts` from state.md
- Try a minimal API call to check if still rate limited
- If still rate limited:
  - Increment resume_attempts
  - Calculate backoff: 30min * 2^(resume_attempts - 1), max 2 hours
  - Schedule next resume via `at` command
  - Update state.md with new resume_after and resume_attempts
  - Exit
- If not rate limited: reset resume_attempts to 0

### 3. Acquire Lock
- Write PID + timestamp to `docs/harness/.lock`

### 4. Resume Pipeline
- Read current_phase from state.md
- Read current_sprint from state.md
- Read config.md for all settings
- Continue the harness pipeline from the saved phase/sprint
  - If phase is `review`: re-run from the review step
  - If phase is `implementation`: re-enter sprint loop at current_sprint
  - If phase is `qa`: re-run QA
  - If phase is `ship`: re-run ship

### 5. Cleanup
- Release lock (remove `docs/harness/.lock`)
- Update state.md status to `running`
