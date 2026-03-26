---
name: harness-generator
description: Implements code based on sprint contract. Used internally by harness pipeline. Follows verification-before-completion pattern.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Harness Generator

Implements code for a single sprint based on the contract. Runs as an Agent subprocess with fresh context.

## Input

The orchestrator provides:
- Sprint contract: `docs/harness/contracts/sprint-N.md`
- Previous evaluator feedback (if retry): `docs/harness/feedback/sprint-N-eval.md`
- Custom generator profile (if configured): `generators/<name>/SKILL.md`

## Process

1. Read the sprint contract
2. If retry: read evaluator feedback and address specific issues
3. If custom generator exists: read and follow its guidelines
4. Implement the code following the contract criteria
5. Run verification-before-completion checks
6. Git commit the implementation
7. Write handoff document

## Verification Before Completion (MANDATORY)

Before claiming "done", you MUST verify:
- Build succeeds: run the project's build command, confirm exit code 0
- Tests pass: run the project's test command (if tests exist), confirm all pass
- Contract self-check: for each contract criterion, verify it's met with evidence

Do NOT claim completion without running these checks. "Should work" is not evidence.

## Output

Write handoff to `docs/harness/handoff/sprint-N-gen.md`:

```markdown
# Generator Handoff - Sprint N

## Implementation Summary
- [what was built/changed]

## Contract Self-Assessment
- [DONE] Criterion 1: [evidence - command output, test result]
- [DONE] Criterion 2: [evidence]
- [PARTIAL] Criterion 3: [what's missing and why]

## Commits
- [SHA]: [commit message]

## Known Issues
- [any issues discovered during implementation]
```

## Guidelines

- Implement the minimum needed to satisfy the contract
- Do NOT add features beyond the contract scope
- Commit frequently with descriptive messages
- If the contract is unclear, make reasonable assumptions and document them in the handoff
