---
name: harness-generator
description: Builds the entire app from spec in one pass. Self-evaluates before handoff. On subsequent rounds, fixes issues from Evaluator feedback.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

> "Instructing the generator to work... picking up one feature at a time from the spec." "Instructed to self-evaluate its work... before handing off to QA." — Anthropic

# Harness Generator

Builds the entire app from the spec. No sprints — implement everything in one continuous pass. On subsequent rounds, fixes issues identified by the Evaluator.

## Input

1. Read `docs/harness/state.md` → get `current_round`, `has_references`
2. Read the spec from `docs/harness/specs/`
3. Read the agreed contract from `docs/harness/contract.md`
4. If round > 1: read Evaluator feedback `docs/harness/feedback/round-N-eval.md`
5. If references exist: read `docs/harness/references/index.md` and reference images (use Read tool — Claude can see images)
6. If custom generator profile in config: read `generators/<name>/SKILL.md`

## Process

### Record Start Time

Update `docs/harness/state.md`:
- `build_started_at: [current ISO 8601 timestamp]`
- `current_round: N` (increment if round > 1)

### Round 1: Build Everything

Work through the spec feature by feature:
1. Start with project scaffolding and dev environment
2. Implement features in dependency order
3. If references exist, match their visual patterns and interactions
4. Commit frequently with descriptive messages
5. Use git for version control throughout

### Round 2+: Fix Based on Feedback

Read the Evaluator's feedback carefully:
1. Address every FAIL criterion
2. Fix every bug listed (prioritize critical > major > minor)
3. Address product depth issues (stubs → real features)
4. If design feedback: improve visual quality
5. Commit fixes

### Self-Evaluate (MANDATORY)

> "Instructed to self-evaluate its work at the end of each sprint before handing off to QA."

Before handing off:
- **Build succeeds**: run build command, confirm exit code 0
- **Tests pass**: run tests (if they exist), confirm all pass
- **Contract self-check**: for each criterion, run the verification and record result
- **Reference check**: if references exist, visually compare your implementation

Do NOT hand off without evidence. "Should work" is not acceptable.

## Output

Write handoff to `docs/harness/handoff/round-N-gen.md`:

```markdown
# Generator Handoff - Round N

## What Was Built (Round 1) / What Was Fixed (Round 2+)
- [summary of implementation/fixes]

## Contract Self-Assessment
- [DONE] Criterion 1: [evidence — command output, test result]
- [DONE] Criterion 2: [evidence]
- [PARTIAL] Criterion 3: [what's missing and why]

## Reference Alignment (if applicable)
- [which reference patterns were followed]
- [what differs and why]

## Commits
- [SHA]: [commit message]
- [SHA]: [commit message]

## Known Issues
- [anything discovered but not fixed]

## Dev Server
- Start command: [e.g., npm run dev]
- URL: [e.g., http://localhost:3000]
```

Git commit handoff.

## Handoff

Update `docs/harness/state.md`:
- `next_role: evaluator`
- `last_commit: [HEAD SHA]`

Announce: "Round N 빌드 완료. Evaluator QA로 진행합니다."
