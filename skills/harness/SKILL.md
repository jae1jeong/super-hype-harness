---
name: harness
description: Long-running app development harness. Planner → Generator → Evaluator with file-based handoff in one continuous session. No sprints — build everything, then QA.
argument-hint: <app description> [--resume] [--no-auto-resume] [--status] [--ref <url-or-image>...]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch]
---

> "I started by removing the sprint construct entirely... find the simplest solution possible, and only increase complexity when needed." — Anthropic

# Super Hype Harness

One continuous session. File-based handoff. No sprints — the Generator builds everything, then the Evaluator tests in a single pass. Failed? Fix and re-test. Repeat until done.

## Arguments

Parse `$ARGUMENTS` for:
- `--resume` → read state.md, continue from pause point
- `--status` → invoke harness-status skill, then stop
- `--no-auto-resume` → set auto_resume: false for this run
- `--ref <url-or-image>` → reference material (repeatable)
- Everything else → treat as the app description

## Bootstrap

### 1. Directory Setup

Create if not exists:
```
docs/harness/specs/
docs/harness/plans/
docs/harness/handoff/
docs/harness/feedback/
docs/harness/references/
```

### 2. Reference Capture (if --ref provided)

For each `--ref` argument:

**If URL:**
```bash
which agent-browser || npm install -g agent-browser
agent-browser install 2>/dev/null || true
agent-browser open <url>
agent-browser screenshot   # → docs/harness/references/ref-N-home.png
agent-browser snapshot     # → docs/harness/references/ref-N-snapshot.md
```
Navigate 2-3 key pages and screenshot each. Then close.

**If image file:**
Copy to `docs/harness/references/ref-N.<ext>`.

Record all references in `docs/harness/references/index.md`.

### 3. Config (docs/harness/config.md)

If config.md doesn't exist, run **Skill Onboarding** (scan for gstack/superpowers, ask 4 category questions), then create:
```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
max_rounds: 5
app_type: web
has_references: true/false

skills:
  brainstorm:
  ceo_review:
  eng_review:
  design_review:
  evaluate_qa:
  debug:
  code_review:
  ship:
```

### 4. Build Log (docs/harness/build-log.md)

```markdown
# Build Log

| Round | Phase | Score | Duration | Cost | Notes |
|-------|-------|-------|----------|------|-------|
```

### 5. State (docs/harness/state.md)

```yaml
---
status: running
paused_at:
resume_after:
resume_attempts: 0
---
## Pipeline State
- project: [extracted from app description]
- spec:
- next_role: brainstorm
- current_round: 0
- build_started_at:
- last_commit:
- last_evaluator_feedback:
- config: docs/harness/config.md
- has_references: true/false
```

### 6. Git Commit bootstrap files.

## Role Loop

After bootstrap, enter the role loop in your current session — no Agent subprocesses.

> "Communication was handled via files: one agent would write a file, another agent would read it."

```
LOOP:
  1. Read docs/harness/state.md → get next_role
  2. Read the corresponding SKILL.md:
     - brainstorm → skills/harness-brainstorm/SKILL.md
     - review    → (see Review section below)
     - planner   → skills/harness-planner/SKILL.md
     - contract  → (see Contract Negotiation below)
     - generator → skills/harness-generator/SKILL.md
     - evaluator → skills/harness-evaluator/SKILL.md
     - qa        → skills/harness-qa/SKILL.md
     - ship      → (see Ship section below)
     - done      → EXIT LOOP
  3. Follow that skill's instructions completely
  4. The skill updates state.md with the next next_role
  5. Git commit checkpoint
  6. Go to step 1
```

### Review Role (built-in)

When next_role is `review`, run reviews on the spec:

**CEO Review** — Is MVP scoped right? Features over/under-scoped? Tech stack realistic?
**Design Review** (web apps only) — Information hierarchy, interaction states, responsive, accessibility
**Engineering Review** — Data model, API design, error handling, security, performance

Issues found → revise spec, re-review. All pass → state.md: `next_role: planner`.

### Contract Negotiation

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal. The two iterated until they agreed."

When next_role is `contract`:
1. **Generator proposes**: Read the spec/plan. Write a contract to `docs/harness/contract.md` listing what will be built and how to verify it.
2. **Evaluator reviews**: Read the contract. Check: are criteria specific enough? Machine-verifiable? Covering edge cases? Write feedback in the same file or a response file.
3. **Iterate**: Generator revises based on feedback. Repeat until both agree.
4. When agreed: state.md → `next_role: generator`.

### Ship Role (built-in)

When next_role is `ship`:
1. Run test suite. All tests must pass.
2. Create PR via `gh pr create` with summary.
3. Display final summary from build-log.md:

```
Pipeline complete!
Project: [name]
Build rounds: N
Total duration: [sum]
QA: [PASS]
PR: [URL]

Build Log:
| Round | Phase     | Score | Duration |
|-------|-----------|-------|----------|
| 1     | Build     |   -   | 2h 7m   |
| 1     | QA        | 6/10  | 8.8m    |
| 2     | Build     |   -   | 1h 2m   |
| 2     | QA        | 8/10  | 6.8m    |
| 3     | Build     |   -   | 10.9m   |
| 3     | QA        | 9/10  | 9.6m    |
```

Update state.md → `next_role: done`, `status: completed`. Git commit.

## Build → QA Rounds

> "moved the evaluator to a single pass at the end of the run rather than grading per sprint"

The Generator builds the ENTIRE app in one go. Then the Evaluator runs a SINGLE QA pass. If it fails, the Generator fixes everything and the Evaluator runs QA again. This repeats for up to `max_rounds` (default: 5).

```
Round 1:
  Generator → builds entire app from spec → handoff
  Evaluator → QA pass → feedback (FAIL, score 6/10)

Round 2:
  Generator → fixes based on feedback → handoff
  Evaluator → QA pass → feedback (FAIL, score 8/10)

Round 3:
  Generator → fixes remaining issues → handoff
  Evaluator → QA pass → feedback (PASS, score 9/10)

→ Ship
```

Each round is logged in build-log.md with duration.

## Rate Limit Handling

The StopFailure hook handles rate limits: pauses state.md, schedules resume via `at` command.
