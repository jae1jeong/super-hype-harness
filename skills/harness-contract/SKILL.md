---
name: harness-contract
description: Reference for sprint contract format. Generator uses this to propose contracts. Not dispatched as separate agent.
allowed-tools: [Read, Write, Glob, Grep]
---

# Sprint Contract Format Reference

This is a reference document for the contract format. In the file-based handoff architecture, the **Generator proposes contracts directly** (not a separate Contract agent).

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal." — Anthropic

## Contract Format

```markdown
# Sprint N Contract: [Sprint Title]

## Completion Criteria

### 1. [Criterion Name]
- **Test**: [exact command or action to verify]
- **Expected**: [exact expected output or behavior]
- **Type**: build | test | api | browser | cli
- **Threshold**: [hard pass/fail condition — if any ONE criterion fails, the sprint fails]

### 2. [Criterion Name]
...

## Reference Alignment (if references exist)
- [which reference patterns this sprint should match]

## Verification Commands
\`\`\`bash
[command 1]
[command 2]
\`\`\`

## Scope Exclusions
- [what is NOT part of this sprint]
```

## Guidelines

- Every criterion must be machine-verifiable (no subjective judgments)
- Include both positive tests (it works) and negative tests (handles errors)
- For web apps: include browser verification steps
- For CLI apps: include CLI invocation tests
- Keep focused: 3-8 criteria per sprint
- Each criterion has a **hard threshold** — "if any one fell below it, the sprint failed"
