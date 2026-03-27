---
name: harness
description: Long-running app development harness. Orchestrates Brainstorm → Review → Plan → Generate → Evaluate → QA → Ship pipeline with context reset. Fully standalone — no external plugin dependencies.
argument-hint: <app description> [--resume] [--no-auto-resume] [--status]
allowed-tools: [Agent, Read, Write, Edit, Bash, Glob, Grep, TaskCreate, TaskUpdate]
---

> Patterns adapted from [gstack](https://github.com/garrytan/gstack) (review workflows, ship pipeline) and [superpowers](https://github.com/obra/superpowers) (verification-before-completion, systematic-debugging, checklist-driven workflows). Harness architecture inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps).

# Super Hype Harness

Orchestrates long-running app development through a multi-phase pipeline. Each phase runs in an isolated Agent subprocess (context reset) except brainstorming which runs in the main session.

All review, debugging, and shipping patterns are built-in — no external plugins required.

## Arguments

Parse `$ARGUMENTS` for:
- `--resume` → invoke resume logic (read state.md, continue from pause point)
- `--status` → invoke harness-status skill, then stop
- `--no-auto-resume` → set auto_resume: false in config.md for this run
- Everything else → treat as the app description

## Initialization

### 1. Directory Setup

Create if not exists:
```
docs/harness/specs/
docs/harness/plans/
docs/harness/contracts/
docs/harness/handoff/
docs/harness/feedback/
```

### 2. Config (docs/harness/config.md)

If config.md doesn't exist, create with defaults:
```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
self_reset_interval: 3
max_retries: 3
max_pivots: 2
app_type: web
```

If `--no-auto-resume` flag: set `auto_resume: false`.

### 3. State (docs/harness/state.md)

Create initial state:
```yaml
---
status: running
reason: initial
paused_at:
resume_after:
resume_attempts: 0
---
## Pipeline State
- project: [extracted from app description]
- spec:
- plan:
- current_phase: brainstorm
- current_sprint: 0
- total_sprints: 0
- last_commit:
- last_evaluator_feedback:
- config: docs/harness/config.md
```

### 4. Lock File

Create `docs/harness/.lock` with current PID and timestamp.

## Phase 1: Brainstorm (Main Session — NOT Agent)

<HARD-GATE>
Do NOT proceed to Phase 2 until brainstorming produces a spec document.
</HARD-GATE>

Run the brainstorming process DIRECTLY in the main session (the user needs to interact):

1. Read `skills/harness-brainstorm/SKILL.md`
2. Follow its instructions: question framework, pushback, scope expansion
3. When complete: spec is written to `docs/harness/specs/YYYY-MM-DD-<name>-spec.md`
4. Detect app_type from the conversation, update config.md
5. Update state.md: `current_phase: review`, update spec path
6. Git commit

## Phase 2: Review (Agent Subprocesses)

<HARD-GATE>
Do NOT proceed to Phase 3 until all reviews pass.
</HARD-GATE>

### Step 2a: CEO Review

Dispatch Agent subprocess to perform a checklist-based scope review of the spec:

**Checklist:**
- Is the MVP appropriately scoped? (not too big, not too small)
- Are features over/under-scoped for the target user?
- Is the tech stack realistic for the goals?
- Are there obvious missing features that would make the product non-viable?
- Is the ambition level appropriate? (too conservative = won't impress, too ambitious = won't finish)

**Parse result:**
- Scope issues found → return to Phase 1 with specific feedback (expand or reduce)
- Approved → continue

### Step 2b: Design Review (web apps only)

If config `app_type` is `web`, dispatch Agent subprocess to perform a design review of the spec:

**Checklist:**
- Information hierarchy — what does the user see first? Is the most important content prominent?
- Key interactions and states — are loading, empty, error, and success states all considered?
- Responsive considerations — does the design degrade gracefully across viewport sizes?
- Accessibility basics — color contrast, keyboard navigation, screen reader considerations

**Parse result:**
- Design issues found → revise spec, re-review
- Approved → continue

If `app_type` is NOT `web`: skip this step.

### Step 2c: Engineering Review

Dispatch Agent subprocess to perform a checklist-based technical review of the spec:

**Checklist:**
- Data model: are entities and relationships well-defined?
- API design: are endpoints, methods, and responses complete and consistent?
- Error handling: are failure modes considered and recovery strategies defined?
- Security: are auth, input validation, and secrets management handled?
- Performance: are there obvious bottlenecks or scalability concerns?

**Parse result:**
- "tech stack change needed" → revise spec, re-review
- "architecture issue" → return to Phase 1
- Approved → continue

Update state.md: `current_phase: implementation`
Git commit.

## Phase 3: Implementation (Sprint Loop)

### Step 3a: Sprint Planning

Dispatch Agent subprocess with `skills/harness-planner/SKILL.md` context:
- Input: the reviewed spec
- Output: `docs/harness/plans/YYYY-MM-DD-plan.md`
- Update state.md: plan path, total_sprints

### Step 3b: Sprint Loop

For each sprint (1 to total_sprints):

#### StatusLine Sentry (Rate Limit Pre-Detection)
Before each sprint, if possible, check rate limit usage. If approaching 90%: complete current sprint, then pause (save state with reason: preemptive_pause, schedule resume).

#### Contract
Dispatch Agent with `skills/harness-contract/SKILL.md`:
- Input: sprint N section from plan.md + config (app_type)
- Output: `docs/harness/contracts/sprint-N.md`

#### Generator-Evaluator Loop

```
retry_count = 0
pivot_count = 0

LOOP:
  # Generate
  Dispatch Agent with skills/harness-generator/SKILL.md:
    Input: contract + previous feedback (if retry) + custom generator profile
    Output: docs/harness/handoff/sprint-N-gen.md + Git commits

  # Evaluate
  Dispatch Agent with skills/harness-evaluator/SKILL.md:
    Input: contract + handoff + custom evaluator profile
    Output: docs/harness/feedback/sprint-N-eval.md

  # Parse Judgment (read ## Judgment section from feedback)
  IF PASS:
    → proceed to next sprint

  IF RETRY:
    retry_count += 1
    IF retry_count <= max_retries:
      # Trend check: compare FAIL count with previous iteration
      IF FAIL count same or increasing AND retry_count >= 2:
        → Invoke Systematic Debugging (see below)
      → goto LOOP with feedback
    ELSE:
      → PIVOT

  IF PIVOT:
    pivot_count += 1
    IF pivot_count <= max_pivots:
      → goto LOOP with pivot direction from evaluator
    ELSE:
      → ESCALATE

  IF ESCALATE:
    Write docs/harness/feedback/sprint-N-escalated.md
    Log the issue and continue to next sprint
```

#### Systematic Debugging (used when evaluator FAIL count is stagnant or increasing)

When the generator-evaluator loop is stuck (FAIL count not decreasing after 2+ retries), dispatch an Agent subprocess that follows this pattern:

1. **Phase 1 — Gather Symptoms**: Read the evaluator feedback, error logs, and failing test output. Enumerate every distinct failure.
2. **Phase 2 — Form Hypothesis**: For each failure, propose the most likely root cause. Rank by probability.
3. **Phase 3 — Test Minimally**: Change ONE variable at a time. Run the smallest possible verification to confirm or reject the hypothesis.
4. **Phase 4 — Implement Fix**: Apply the confirmed fix. Re-run the evaluator to verify the FAIL count decreases.

The Agent writes its findings to `docs/harness/feedback/sprint-N-investigation.md` and returns the fix to the generator-evaluator loop.

#### Sprint Checkpoint
After each sprint completes:
- Update state.md: current_sprint, last_commit, last_evaluator_feedback
- Git commit checkpoint

#### Self-Reset Check
Every `self_reset_interval` sprints (default: 3):
1. Save state.md with `status: self_resetting`
2. Git commit
3. Run `claude -p "/harness --resume"` via Bash (background)
4. End current execution (the new session picks up)

## Phase 4: QA

Update state.md: `current_phase: qa`

Dispatch Agent with `skills/harness-qa/SKILL.md`:
- Input: config (app_type), spec (user journey)
- Output: `docs/harness/qa-report.md`
- If bugs found: auto-fix loop within the agent

Git commit.

## Phase 5: Ship

Update state.md: `current_phase: ship`

Ship the project:
1. Run the test suite (`npm test`, `pytest`, or whatever the project uses). All tests must pass.
2. Create a PR via `gh pr create` with a summary of what was built.
3. Display the PR URL.

If the test suite fails, use the Systematic Debugging pattern (Phase 1-4 from above) to fix failures before creating the PR.

## Completion

1. Update state.md: `status: completed`
2. Remove lock file (`docs/harness/.lock`)
3. Git commit final state
4. Display summary:

```
Pipeline complete!
Project: [name]
Sprints: N completed, M escalated
Total commits: [count]
QA: [PASS/FAIL]
PR: [URL if created]
```
