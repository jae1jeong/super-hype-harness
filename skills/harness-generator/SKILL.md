---
name: harness-generator
description: Implements code for the current sprint, proposes contract, self-evaluates before handoff. File-based handoff to Evaluator.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal to make sure the generator was building the right thing." — Anthropic

# Harness Generator

Implements code for the current sprint. Proposes a contract, builds to it, self-evaluates, then hands off to Evaluator via files.

## Input

1. Read `docs/harness/state.md` → get `current_sprint`, `plan`, `has_references`
2. Read the sprint section from the plan file
3. If retry: read `docs/harness/feedback/sprint-N-eval.md` for what failed
4. If references exist: read `docs/harness/references/index.md` and reference images (use Read tool on images — Claude can see them)
5. If custom generator profile exists in config: read `generators/<name>/SKILL.md`

## Step 1: Propose Contract

> "The two iterated until they agreed on what 'done' looked like before any code was written."

Write a proposed contract to `docs/harness/contracts/sprint-N.md`:

```markdown
# Sprint N Contract: [Sprint Title]

## Completion Criteria

### 1. [Criterion Name]
- **Test**: [exact command or action]
- **Expected**: [exact expected output or behavior]
- **Type**: build | test | api | browser | cli
- **Threshold**: [hard pass/fail condition]

### 2. [Criterion Name]
...

## Reference Alignment (if references exist)
- [which reference patterns this sprint should match]
- [specific layout/interaction elements to replicate]

## Verification Commands
\`\`\`bash
[command 1]
[command 2]
\`\`\`

## Scope Exclusions
- [what is NOT part of this sprint]
```

Every criterion must be machine-verifiable. Include both positive and negative tests. 3-8 criteria per sprint.

## Step 2: Record Start Time

Update `docs/harness/state.md`:
- `feature_started_at: [current ISO 8601 timestamp]`

## Step 3: Implement

Build the code to satisfy the contract criteria.
- Implement minimum needed to satisfy the contract
- Do NOT add features beyond the contract scope
- If references exist, match their visual patterns and interactions
- Commit frequently with descriptive messages

## Step 4: Self-Evaluate (MANDATORY)

> "Instructed to self-evaluate its work at the end of each sprint before handing off to QA."

Before claiming done:
- **Build succeeds**: run the project's build command, confirm exit code 0
- **Tests pass**: run test command (if tests exist), confirm all pass
- **Contract self-check**: for each criterion, run the verification command and record the result
- **Reference check**: if references exist, take a screenshot of your implementation and compare visually

Do NOT hand off without running these checks. "Should work" is not evidence.

## Step 5: Write Handoff

Write to `docs/harness/handoff/sprint-N-gen.md`:

```markdown
# Generator Handoff - Sprint N

## Implementation Summary
- [what was built/changed]

## Contract Self-Assessment
- [DONE] Criterion 1: [evidence — command output, test result]
- [DONE] Criterion 2: [evidence]
- [PARTIAL] Criterion 3: [what's missing and why]

## Reference Alignment (if applicable)
- [which reference patterns were followed]
- [what differs from the reference and why]

## Commits
- [SHA]: [commit message]

## Known Issues
- [any issues discovered during implementation]

## Dev Server
- Start command: [e.g., npm run dev]
- URL: [e.g., http://localhost:3000]
- Port: [e.g., 3000]
```

Git commit the handoff + contract files.

## Handoff

After writing handoff:
1. Update `docs/harness/state.md`:
   - `next_role: evaluator`
   - `last_commit: [HEAD SHA]`
2. Announce: "Sprint N 구현 완료. state.md에 따라 evaluator 단계로 진행합니다."
