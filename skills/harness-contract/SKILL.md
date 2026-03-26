---
name: harness-contract
description: Negotiates testable completion criteria between Generator and Evaluator for each sprint. Used internally by the harness pipeline.
allowed-tools: [Read, Write, Glob, Grep]
---

# Harness Contract

Converts a sprint's plan section into a detailed, testable contract. Runs as an Agent subprocess.

## Input

- Sprint plan section from `docs/harness/plans/YYYY-MM-DD-plan.md` (specific sprint number provided by orchestrator)
- Config from `docs/harness/config.md` (for app_type)

## Process

1. Read the sprint's Done Definition from the plan
2. For each Done item, generate:
   - A specific, verifiable test criterion
   - The exact command or action to verify it
   - Expected output/behavior
3. Add scope exclusions (what is NOT part of this sprint)

## Output Format

Write to `docs/harness/contracts/sprint-N.md`:

```markdown
# Sprint N Contract: [Sprint Title]

## Completion Criteria

### 1. [Criterion Name]
- **Test**: [exact command or action]
- **Expected**: [exact expected output or behavior]
- **Type**: build | test | api | browser | cli

### 2. [Criterion Name]
...

## Verification Commands

\`\`\`bash
# Run all verifications in sequence
[command 1]
[command 2]
...
\`\`\`

## Scope Exclusions
- [What is explicitly NOT part of this sprint]
- [Features deferred to later sprints]
```

## Guidelines

- Every criterion must be machine-verifiable (no subjective judgments)
- Include both positive tests (it works) and negative tests (it handles errors) where relevant
- For web apps (app_type: web), include browser verification steps
- For CLI apps (app_type: cli), include CLI invocation tests
- Keep contracts focused: 3-8 criteria per sprint
