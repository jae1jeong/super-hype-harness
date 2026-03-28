---
name: harness
description: Long-running app development harness. File-based handoff between Planner, Generator, and Evaluator in one continuous session.
argument-hint: <app description> [--resume] [--no-auto-resume] [--status] [--ref <url-or-image>...]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch]
---

> Architecture adapted from [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps). "Communication was handled via files: one agent would write a file, another agent would read it and respond either within that file or with a new file."

# Super Hype Harness

One continuous session. No orchestrator. Agents hand off work via files.

## Arguments

Parse `$ARGUMENTS` for:
- `--resume` → read state.md, continue from pause point
- `--status` → invoke harness-status skill, then stop
- `--no-auto-resume` → set auto_resume: false for this run
- `--ref <url-or-image>` → reference material (repeatable)
- Everything else → treat as the app description

## Bootstrap

The harness skill ONLY bootstraps. After setup, you transition into roles by reading each role's SKILL.md and following its instructions directly in this session.

### 1. Directory Setup

Create if not exists:
```
docs/harness/specs/
docs/harness/plans/
docs/harness/contracts/
docs/harness/handoff/
docs/harness/feedback/
docs/harness/references/
```

### 2. Reference Capture (if --ref provided)

For each `--ref` argument:

**If URL:**
```bash
# Ensure agent-browser is installed
which agent-browser || npm install -g agent-browser
agent-browser install 2>/dev/null || true

# Capture reference site
agent-browser open <url>
agent-browser screenshot   # Save as docs/harness/references/ref-N-home.png
agent-browser snapshot     # Save text snapshot to docs/harness/references/ref-N-snapshot.md
```
Navigate 2-3 key pages and screenshot each. Then close.

**If image file:**
Copy to `docs/harness/references/ref-N.<ext>`.

Record all references in `docs/harness/references/index.md`:
```markdown
# References
1. [ref-1-home.png](ref-1-home.png) — https://cal.com (homepage)
2. [ref-1-dashboard.png](ref-1-dashboard.png) — https://cal.com (dashboard)
3. [ref-2.png](ref-2.png) — mockup.png (user provided)
```

### 3. Config (docs/harness/config.md)

If config.md doesn't exist, run **Skill Onboarding** (see below), then create:
```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
max_retries: 3
max_pivots: 2
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

If `--no-auto-resume`: set `auto_resume: false`.

### Skill Onboarding (first run only)

Same as before — scan for installed skills (gstack, superpowers), ask user 4 category questions via AskUserQuestion, map selections to config.

### 4. Sprint Log (docs/harness/sprint-log.md)

```markdown
# Sprint Log

| Sprint | Status | Score | Retries | Pivots | Started | Finished | Duration | Notes |
|--------|--------|-------|---------|--------|---------|----------|----------|-------|
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
- plan:
- next_role: brainstorm
- current_sprint: 0
- total_sprints: 0
- retry_count: 0
- pivot_count: 0
- feature_started_at:
- last_commit:
- last_evaluator_feedback:
- config: docs/harness/config.md
- has_references: true/false
```

### 6. Git Commit

Commit all bootstrap files.

## Role Loop

After bootstrap, enter the role loop. This runs in your current session — no Agent subprocesses.

```
LOOP:
  1. Read docs/harness/state.md → get next_role
  2. Read the corresponding SKILL.md:
     - brainstorm → skills/harness-brainstorm/SKILL.md
     - review    → (see Review section below)
     - planner   → skills/harness-planner/SKILL.md
     - generator → skills/harness-generator/SKILL.md
     - evaluator → skills/harness-evaluator/SKILL.md
     - qa        → skills/harness-qa/SKILL.md
     - ship      → (see Ship section below)
     - done      → EXIT LOOP
  3. Follow that skill's instructions completely
  4. The skill updates state.md with the next next_role when done
  5. Git commit checkpoint
  6. Go to step 1
```

Each role reads its input from files written by the previous role. Each role writes its output to files for the next role. This is the "one agent writes a file, another reads it" pattern.

### Review Role (built-in)

When next_role is `review`, run three reviews on the spec:

**CEO Review** — check config.skills.ceo_review:
- If set: invoke that skill on the spec
- If empty, check these yourself:
  - Is the MVP appropriately scoped?
  - Are features over/under-scoped?
  - Is the tech stack realistic?
  - Missing features that would make it non-viable?

**Design Review** (web apps only) — check config.skills.design_review:
- If set: invoke that skill
- If empty: check information hierarchy, interaction states, responsive, accessibility

**Engineering Review** — check config.skills.eng_review:
- If set: invoke that skill
- If empty: check data model, API design, error handling, security, performance

If issues found: update spec, re-review. When all pass: update state.md → `next_role: planner`.

### Ship Role (built-in)

When next_role is `ship`:

Check config.skills.ship:
- If set: invoke that skill
- If empty:
  1. Run test suite. All tests must pass.
  2. Create PR via `gh pr create` with summary.
  3. Display PR URL.

Display final summary (read from sprint-log.md):
```
Pipeline complete!
Project: [name]
Sprints: N completed, M escalated
Total duration: [sum]
Total retries: [sum]
QA: [PASS/FAIL]
PR: [URL]

Sprint Log:
| Sprint | Status | Score | Retries | Duration |
|--------|--------|-------|---------|----------|
| ...    | ...    | ...   | ...     | ...      |
```

Update state.md → `next_role: done`, `status: completed`. Remove lock file. Git commit.

## Rate Limit Handling

The StopFailure hook (`hooks/stop-failure-handler.sh`) handles rate limits:
1. Detects rate_limit error
2. Updates state.md to paused
3. Schedules `claude -p "/harness --resume"` via `at` command

Resume reads state.md and re-enters the role loop at the saved next_role.
