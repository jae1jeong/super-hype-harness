# Evaluation Criteria

## Judgment Rules

### PASS
ALL contract items verified as passing. Score (X/10) is advisory only.

### RETRY
1 or more contract items FAIL. Return with specific feedback for Generator.
- Max retries per sprint: configurable via `max_retries` in config.md (default: 3)

### PIVOT
RETRY count exceeds max_retries. Current approach cannot solve the problem.
- Evaluator must propose a concrete alternative approach
- Max pivots per sprint: configurable via `max_pivots` in config.md (default: 2)

### ESCALATE
PIVOT count exceeds max_pivots. Issue is logged and sprint is skipped.
- Write escalation details to `docs/harness/feedback/sprint-N-escalated.md`

## Trend Detection
Compare FAIL item count across last 2 iterations of the same sprint:
- Decreasing: continue with incremental improvement
- Same or increasing: signal for root cause investigation (orchestrator triggers systematic debugging)

## Scoring (Advisory)
Rate overall quality 1-10 as a reference metric. This does NOT affect PASS/RETRY/PIVOT judgment.
