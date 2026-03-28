---
name: harness-contract
description: Contract negotiation between Generator and Evaluator. Generator proposes, Evaluator reviews, iterate until agreed.
allowed-tools: [Read, Write, Glob, Grep]
---

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal to make sure the generator was building the right thing. The two iterated until they agreed." — Anthropic
> Example: "Sprint 3 alone had 27 criteria covering the level editor."

# Contract Negotiation

The Generator and Evaluator agree on what "done" looks like before any code is written. This happens via file-based back-and-forth.

## Process

### Step 1: Generator Proposes

Read the plan from `docs/harness/plans/`. Write a contract proposal to `docs/harness/contract.md`:

```markdown
# Contract: [Project Name]

## What Will Be Built
[high-level summary of the full app]

## Completion Criteria

### 1. [Criterion Name]
- **Test**: [exact command or action to verify]
- **Expected**: [exact expected output or behavior]
- **Type**: build | test | api | browser | cli

### 2. [Criterion Name]
...
(aim for 15-30 criteria for a full app)

## Reference Alignment (if references exist)
- [which reference patterns will be matched]

## Verification Commands
\`\`\`bash
[commands to verify]
\`\`\`
```

### Step 2: Evaluator Reviews

Switch to Evaluator perspective. Read the proposed contract and check:
- Are criteria specific enough? Machine-verifiable?
- Are edge cases covered? (empty states, errors, invalid input)
- For web apps: are browser verification steps included?
- Are there enough criteria? (15-30 for a full app)
- Do criteria cover ALL features in the plan?

Write review comments directly in the contract file under a `## Review` section.

### Step 3: Iterate

Generator reads the review, revises the contract. Evaluator reviews again. Repeat until the `## Review` section says "AGREED".

### Step 4: Handoff

When agreed, update `docs/harness/state.md`:
- `next_role: generator`

## Guidelines

- Every criterion must have a hard threshold — pass or fail, no "mostly works"
- "Each criterion had a hard threshold, and if any one fell below it, the sprint failed"
- Include both positive tests (it works) and negative tests (handles errors)
- For web apps: include browser verification (navigate, click, verify state)
- Criteria should cover: functionality, data persistence, error handling, UI state
