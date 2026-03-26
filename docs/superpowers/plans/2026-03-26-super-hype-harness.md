# Super Hype Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that orchestrates long-running app development via a Planner → Generator → Evaluator pipeline with context reset, skill ecosystem integration, and rate limit auto-resume.

**Architecture:** Pure SKILL.md-based plugin. The `/harness` command is the orchestrator that runs brainstorming in the main session, then dispatches Agent subprocesses for each pipeline phase. State is persisted via markdown files in `docs/harness/` and Git commits. gstack/superpowers skills are called when available, with built-in fallbacks.

**Tech Stack:** Claude Code Plugin (SKILL.md), Bash (hooks), vercel-labs/agent-browser (QA)

**Spec:** `docs/harness/specs/2026-03-26-super-hype-harness-design.md`

---

## File Structure

```
super-hype-harness/
├── .claude-plugin/
│   └── plugin.json                          # Plugin metadata
├── skills/
│   ├── harness/
│   │   └── SKILL.md                         # Main orchestrator (/harness command)
│   ├── harness-brainstorm/
│   │   ├── SKILL.md                         # Interactive brainstorming skill
│   │   └── references/
│   │       └── question-framework.md        # 4-phase question framework
│   ├── harness-planner/
│   │   └── SKILL.md                         # Spec → sprint decomposition
│   ├── harness-contract/
│   │   └── SKILL.md                         # Sprint contract negotiation
│   ├── harness-generator/
│   │   └── SKILL.md                         # Code implementation agent
│   ├── harness-evaluator/
│   │   ├── SKILL.md                         # Independent QA agent
│   │   └── references/
│   │       └── evaluation-criteria.md       # Scoring rubric & judgment rules
│   ├── harness-qa/
│   │   └── SKILL.md                         # Final QA (browser/cli/library)
│   ├── harness-status/
│   │   └── SKILL.md                         # Progress display (/harness-status)
│   └── harness-resume/
│       └── SKILL.md                         # Resume logic (internal, not user-facing)
├── generators/
│   ├── default/
│   │   └── SKILL.md                         # Default fullstack generator
│   ├── frontend/
│   │   └── SKILL.md                         # Frontend-focused generator
│   └── README.md                            # How to create custom generators
├── evaluators/
│   ├── default/
│   │   └── SKILL.md                         # Default code review evaluator
│   ├── browser-qa/
│   │   └── SKILL.md                         # agent-browser QA evaluator
│   ├── design-qa/
│   │   └── SKILL.md                         # Design quality evaluator
│   └── README.md                            # How to create custom evaluators
├── hooks/
│   └── stop-failure-handler.sh              # StopFailure hook for rate limit
├── LICENSE
└── README.md
```

---

### Task 1: Plugin Scaffold & Metadata

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `LICENSE`
- Create: `README.md`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "super-hype-harness",
  "description": "Long-running app development harness: Planner → Generator → Evaluator pipeline with context reset and skill orchestration",
  "version": "0.1.0",
  "author": {
    "name": "jaewon"
  },
  "repository": "https://github.com/jaewon/super-hype-harness",
  "license": "MIT",
  "keywords": ["harness", "pipeline", "long-running", "generator", "evaluator", "orchestration"]
}
```

- [ ] **Step 2: Create LICENSE (MIT)**

Standard MIT license file.

- [ ] **Step 3: Create README.md**

```markdown
# Super Hype Harness

Long-running app development harness for Claude Code. Orchestrates a
Planner → Generator → Evaluator pipeline with automatic context reset,
skill ecosystem integration (gstack/superpowers), and rate limit auto-resume.

Inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps).

## Install

\`\`\`bash
claude plugins install github:jaewon/super-hype-harness
\`\`\`

## Usage

\`\`\`bash
/harness "daily briefing app for my Google Calendar"
/harness-status
/harness --resume
\`\`\`

## Requirements

- Claude Code (latest)

### Optional (enhanced features)

- [gstack](https://github.com/garrytan/gstack) — plan-ceo-review, plan-eng-review, review, ship
- [superpowers](https://github.com/obra/superpowers) — brainstorming patterns
- [agent-browser](https://github.com/vercel-labs/agent-browser) — browser QA

## How It Works

1. **Brainstorm** — Interactive Q&A to flesh out your app idea (office-hours style)
2. **Review** — CEO review (scope/ambition) + Eng review (architecture/security)
3. **Plan** — Decompose spec into sprints with testable contracts
4. **Build** — Generator implements, Evaluator verifies (GAN-inspired loop)
5. **QA** — Full app verification (browser for web, tests for CLI/library)
6. **Ship** — PR creation and deployment

Each phase runs in an isolated Agent subprocess (context reset).
Rate limit auto-resume keeps the pipeline running across sessions.

## Extending

Add custom generators in `generators/` and evaluators in `evaluators/`.
See `generators/README.md` and `evaluators/README.md` for details.
```

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json LICENSE README.md
git commit -m "chore: scaffold plugin with metadata and README"
```

---

### Task 2: Harness Brainstorm Skill

**Files:**
- Create: `skills/harness-brainstorm/SKILL.md`
- Create: `skills/harness-brainstorm/references/question-framework.md`

- [ ] **Step 1: Create question-framework.md**

This reference file contains the 4-phase question framework from the spec (Vision, Scope, Tech, UX Flow). It will be read by the brainstorm skill at runtime.

```markdown
# Harness Brainstorm Question Framework

## Phase 1: Vision (What & Why)
- What problem does this app solve? (specific pain, not abstract)
- Who uses it? (persona, not "everyone")
- What's different from alternatives? (unique value)
- What does "done" look like? (success criteria)

## Phase 2: Scope
- Must-have features (MVP — ruthlessly minimal)
- Nice-to-have features (post-MVP)
- Explicit exclusions (what we will NOT build)
- AI integration points (where Claude/LLM adds value)

## Phase 3: Tech Decisions
- Frontend: React / Vue / Svelte / other
- Backend: Express / FastAPI / Next.js / other
- Database: SQLite / PostgreSQL / none
- Deployment: Vercel / local / other
- External APIs: third-party services needed

## Phase 4: UX Flow
- Key screens/views (count and purpose)
- User journey: first visit → core value delivery
- Authentication: required? method?
- Responsive: mobile support needed?
```

- [ ] **Step 2: Create harness-brainstorm SKILL.md**

This is the interactive brainstorming skill that runs in the main session. It uses the office-hours pattern: pushback, scope expansion, one question at a time.

Key behaviors:
- Read `references/question-framework.md` at start
- Ask one question at a time, prefer multiple choice
- Push back on user framing ("you said X but what you described is Y")
- Expand scope ambitiously, respect user pullback
- Output: `docs/harness/specs/YYYY-MM-DD-<name>-spec.md`
- Git commit the spec
- Detect app_type (web/cli/library) and write to config

- [ ] **Step 3: Commit**

```bash
git add skills/harness-brainstorm/
git commit -m "feat: add harness-brainstorm skill with question framework"
```

---

### Task 3: Harness Planner Skill

**Files:**
- Create: `skills/harness-planner/SKILL.md`

- [ ] **Step 1: Create harness-planner SKILL.md**

Model-invoked skill that takes a reviewed spec and decomposes it into sprints.

Key behaviors:
- Read spec from `docs/harness/specs/`
- Generate sprint plan with: overview, per-sprint goals, Done definitions, verification methods
- Output: `docs/harness/plans/YYYY-MM-DD-plan.md`
- Git commit the plan
- Sprint count should be ambitious but realistic (5-15 sprints typical)

- [ ] **Step 2: Commit**

```bash
git add skills/harness-planner/
git commit -m "feat: add harness-planner skill for sprint decomposition"
```

---

### Task 4: Harness Contract Skill

**Files:**
- Create: `skills/harness-contract/SKILL.md`

- [ ] **Step 1: Create harness-contract SKILL.md**

Model-invoked skill that converts a sprint's plan section into testable completion criteria.

Key behaviors:
- Read the sprint section from plan.md
- Read config for app_type
- Generate contract with: testable criteria, verification methods (code review + browser/test commands), scope exclusions
- Output: `docs/harness/contracts/sprint-N.md`

- [ ] **Step 2: Commit**

```bash
git add skills/harness-contract/
git commit -m "feat: add harness-contract skill for sprint contracts"
```

---

### Task 5: Harness Generator Skill + Default Generator

**Files:**
- Create: `skills/harness-generator/SKILL.md`
- Create: `generators/default/SKILL.md`
- Create: `generators/frontend/SKILL.md`
- Create: `generators/README.md`

- [ ] **Step 1: Create harness-generator SKILL.md**

Model-invoked skill that implements code based on sprint contract.

Key behaviors:
- Read sprint contract from `docs/harness/contracts/sprint-N.md`
- Read previous evaluator feedback if exists (retry scenario)
- Read custom generator skill from `generators/<name>/SKILL.md` if config specifies
- Implement code following the contract
- verification-before-completion: must verify build succeeds, tests pass before claiming done
- Git commit implementation
- Output: `docs/harness/handoff/sprint-N-gen.md`

- [ ] **Step 2: Create generators/default/SKILL.md**

Default fullstack generator profile. Defines coding standards, tech preferences, commit conventions.

- [ ] **Step 3: Create generators/frontend/SKILL.md**

Frontend-focused generator profile. Emphasizes UI quality, component design, responsive layouts.

- [ ] **Step 4: Create generators/README.md**

Guide for creating custom generators.

```markdown
# Custom Generators

Create a new directory under `generators/` with a `SKILL.md` file.

## Example

\`\`\`
generators/
└── my-generator/
    └── SKILL.md
\`\`\`

## SKILL.md Format

\`\`\`yaml
---
name: my-generator
description: Description of this generator's specialization
---

# My Generator

## Tech Stack
- [preferred technologies]

## Coding Standards
- [rules the generator should follow]

## Patterns
- [architectural patterns to use]
\`\`\`

## Activate

Set in `docs/harness/config.md`:
\`\`\`yaml
generator: my-generator
\`\`\`
```

- [ ] **Step 5: Commit**

```bash
git add skills/harness-generator/ generators/
git commit -m "feat: add harness-generator skill with default and frontend generators"
```

---

### Task 6: Harness Evaluator Skill + Default/Browser/Design Evaluators

**Files:**
- Create: `skills/harness-evaluator/SKILL.md`
- Create: `skills/harness-evaluator/references/evaluation-criteria.md`
- Create: `evaluators/default/SKILL.md`
- Create: `evaluators/browser-qa/SKILL.md`
- Create: `evaluators/design-qa/SKILL.md`
- Create: `evaluators/README.md`

- [ ] **Step 1: Create evaluation-criteria.md reference**

Scoring rubric and judgment rules from spec:
- PASS: all contract items pass (score is advisory)
- RETRY: 1+ FAIL items, return with feedback
- PIVOT: RETRY exceeds max_retries
- ESCALATE: PIVOT exceeds max_pivots
- Trend detection: compare FAIL count across last 2 iterations

- [ ] **Step 2: Create harness-evaluator SKILL.md**

Model-invoked skill that independently verifies Generator output.

Key behaviors:
- NO Write/Edit tools — read-only verification
- Read sprint contract + generator handoff
- Distrust generator's self-assessment
- Run builds/tests via Bash to verify claims
- Read custom evaluator skill from `evaluators/<name>/SKILL.md`
- Output: `docs/harness/feedback/sprint-N-eval.md` with PASS/RETRY/PIVOT/ESCALATE

- [ ] **Step 3: Create evaluators/default/SKILL.md**

Code review focused evaluator. Checks code quality, test coverage, contract compliance.

- [ ] **Step 4: Create evaluators/browser-qa/SKILL.md**

agent-browser based evaluator for web apps. Navigates pages, clicks elements, verifies state.

- [ ] **Step 5: Create evaluators/design-qa/SKILL.md**

Design quality evaluator. Checks visual consistency, spacing, typography, layout.

- [ ] **Step 6: Create evaluators/README.md**

Guide for creating custom evaluators (same pattern as generators/README.md).

- [ ] **Step 7: Commit**

```bash
git add skills/harness-evaluator/ evaluators/
git commit -m "feat: add harness-evaluator skill with default, browser-qa, and design-qa evaluators"
```

---

### Task 7: Harness QA Skill

**Files:**
- Create: `skills/harness-qa/SKILL.md`

- [ ] **Step 1: Create harness-qa SKILL.md**

Model-invoked skill for final QA after all sprints complete.

Key behaviors:
- Read config for app_type
- web: start dev server, run agent-browser QA scenarios, stop server
- cli: run integration tests + CLI execution verification
- library: run test suite + API usage scenario verification
- Auto-fix bugs found + re-verify loop
- Output: `docs/harness/qa-report.md`

- [ ] **Step 2: Commit**

```bash
git add skills/harness-qa/
git commit -m "feat: add harness-qa skill with app_type-based QA strategies"
```

---

### Task 8: Harness Status Skill

**Files:**
- Create: `skills/harness-status/SKILL.md`

- [ ] **Step 1: Create harness-status SKILL.md**

User-invoked skill (`/harness-status`) that reads pipeline state and displays progress.

Key behaviors:
- Read `docs/harness/state.md` if exists
- Read feedback files to show sprint scores
- Display: project name, current phase, sprint progress, auto-resume status, last commit
- Minimal output, easy to scan

- [ ] **Step 2: Commit**

```bash
git add skills/harness-status/
git commit -m "feat: add harness-status skill for progress display"
```

---

### Task 9: Harness Resume Logic

**Files:**
- Create: `skills/harness-resume/SKILL.md`

- [ ] **Step 1: Create harness-resume SKILL.md**

Internal skill (not user-facing, invoked by `/harness --resume`).

Key behaviors:
- Read `docs/harness/state.md`
- Verify Git state: compare last_commit with HEAD, warn on mismatch
- Check lock file `docs/harness/.lock` for concurrent execution
- Acquire lock, resume pipeline from saved phase/sprint
- Release lock on completion
- **Exponential backoff**: if still rate limited on resume, re-schedule with increasing delay (30min → 1h → 2h). Track retry count in state.md field `resume_attempts`.

- [ ] **Step 2: Commit**

```bash
git add skills/harness-resume/
git commit -m "feat: add harness-resume logic with exponential backoff"
```

---

### Task 10: Rate Limit Hook

**Files:**
- Create: `hooks/stop-failure-handler.sh`

- [ ] **Step 1: Create stop-failure-handler.sh**

```bash
#!/bin/bash
# StopFailure hook for rate limit auto-resume
# Reads JSON from stdin, detects rate_limit, saves state, schedules resume

INPUT=$(cat)
ERROR=$(echo "$INPUT" | jq -r '.error // empty')

if [ "$ERROR" != "rate_limit" ]; then
  exit 0
fi

HARNESS_DIR="docs/harness"
STATE_FILE="$HARNESS_DIR/state.md"
CONFIG_FILE="$HARNESS_DIR/config.md"

# Check if harness is running (state.md exists with status: running)
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

STATUS=$(grep "^status:" "$STATE_FILE" | head -1 | awk '{print $2}')
if [ "$STATUS" != "running" ]; then
  exit 0
fi

# Check auto_resume setting (covers both config and --no-auto-resume flag)
# The orchestrator writes auto_resume: false to config.md when --no-auto-resume is used
if [ -f "$CONFIG_FILE" ]; then
  AUTO_RESUME=$(grep "^auto_resume:" "$CONFIG_FILE" | awk '{print $2}')
  if [ "$AUTO_RESUME" = "false" ]; then
    sed -i '' 's/^status: running/status: paused/' "$STATE_FILE"
    sed -i '' "s/^reason:.*/reason: rate_limit/" "$STATE_FILE"
    osascript -e "display notification \"Harness paused (rate limit). Auto-resume disabled.\" with title \"Super Hype Harness\"" 2>/dev/null
    exit 0
  fi
fi

# Update state
PAUSED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i '' 's/^status: running/status: paused/' "$STATE_FILE"
sed -i '' "s/^reason:.*/reason: rate_limit/" "$STATE_FILE"
sed -i '' "s/^paused_at:.*/paused_at: $PAUSED_AT/" "$STATE_FILE"

# Try to parse resets_at from StatusLine JSON cache
# 1st priority: StatusLine JSON rate_limits.five_hour.resets_at
STATUSLINE_CACHE="$HOME/.claude/statusline-cache.json"
RESETS_AT=""
if [ -f "$STATUSLINE_CACHE" ]; then
  RESETS_AT=$(jq -r '.rate_limits.five_hour.resets_at // empty' "$STATUSLINE_CACHE" 2>/dev/null)
fi

if [ -n "$RESETS_AT" ] && [ "$RESETS_AT" != "null" ]; then
  # Use actual reset time from StatusLine
  RESUME_EPOCH="$RESETS_AT"
else
  # 2nd priority: default 5 hours from now
  RESUME_EPOCH=$(($(date +%s) + 18000))
fi

RESUME_AT=$(date -u -r "$RESUME_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")
sed -i '' "s/^resume_after:.*/resume_after: $RESUME_AT/" "$STATE_FILE"

# Initialize resume_attempts counter for exponential backoff
CURRENT_ATTEMPTS=$(grep "^resume_attempts:" "$STATE_FILE" | awk '{print $2}')
if [ -z "$CURRENT_ATTEMPTS" ]; then
  echo "resume_attempts: 0" >> "$STATE_FILE"
fi

# Schedule resume via at command
RESUME_TIME=$(date -r "$RESUME_EPOCH" +"%H:%M %m/%d/%Y")
echo "claude -p '/harness --resume'" | at "$RESUME_TIME" 2>/dev/null

# Notify user
osascript -e "display notification \"Harness paused (rate limit). Auto-resume at $RESUME_AT\" with title \"Super Hype Harness\"" 2>/dev/null
```

- [ ] **Step 2: Make executable**

```bash
chmod +x hooks/stop-failure-handler.sh
```

- [ ] **Step 3: Commit**

```bash
git add hooks/
git commit -m "feat: add StopFailure hook for rate limit auto-resume"
```

---

### Task 11: Main Orchestrator Skill (`/harness`)

**Files:**
- Create: `skills/harness/SKILL.md`

This is the core orchestrator — the most complex skill. Split into 5 steps for manageability.

- [ ] **Step 1: SKILL.md frontmatter + argument parsing + initialization**

Write the top section of `skills/harness/SKILL.md`:

```yaml
---
name: harness
description: Long-running app harness pipeline. Brainstorm → Plan → Generate → Evaluate → QA → Ship.
argument-hint: <app description> [--resume] [--no-auto-resume] [--status]
allowed-tools: [Agent, Read, Write, Edit, Bash, Glob, Grep, TaskCreate, TaskUpdate]
---
```

Content for this step:
- Argument parsing logic: detect `--resume`, `--no-auto-resume`, `--status`, or treat as app description
- `--no-auto-resume`: write `auto_resume: false` to config.md (so hook reads it)
- `--status`: invoke harness-status skill and exit
- `--resume`: invoke harness-resume logic and exit
- Directory initialization: create `docs/harness/{specs,plans,contracts,handoff,feedback}/` if not exists
- config.md initialization with defaults:

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

- state.md initialization:

```yaml
---
status: running
reason: initial
paused_at:
resume_after:
resume_attempts: 0
---
## Pipeline State
- project: [from argument]
- spec:
- plan:
- current_phase: brainstorm
- current_sprint: 0
- total_sprints: 0
- last_commit:
- last_evaluator_feedback:
- config: docs/harness/config.md
```

- gstack detection: check if `plan-ceo-review`, `plan-eng-review`, `review`, `ship`, `investigate` skills are available. If not, display fallback warning:

```
[harness] gstack not installed — running in fallback mode.
plan-ceo-review, plan-eng-review, review, ship will use simplified alternatives.
For full features: claude plugins install github:garrytan/gstack
```

- Lock file management: create `docs/harness/.lock` with PID + timestamp

- [ ] **Step 2: Brainstorm + review phase dispatch**

Continue the SKILL.md with:

- Brainstorm execution (inline, NOT Agent):
  - Read `skills/harness-brainstorm/SKILL.md` and follow its instructions
  - After brainstorm completes: update state.md `current_phase: review`, Git commit
  - Detect `app_type` from brainstorm result, update config.md

- Review phase dispatch (all as Agent subprocesses):
  - **plan-ceo-review** Agent: if gstack available, invoke `plan-ceo-review` skill. If not, run fallback (checklist-based scope review: MVP appropriateness, feature over/under-scoping, technical feasibility).
    - Parse result: "scope too small" → re-brainstorm expansion, "scope too large" → re-brainstorm reduction, "approved" → continue
  - **plan-design-review** Agent: if gstack available AND app_type: web, invoke `plan-design-review`. Otherwise skip.
  - **plan-eng-review** Agent: if gstack available, invoke `plan-eng-review`. If not, run fallback (checklist-based tech review: data model, API design, error handling, security).
    - Parse result: "tech stack change needed" → revise spec, "architecture issue" → re-brainstorm, "approved" → continue
  - After all reviews pass: update state.md `current_phase: implementation`, Git commit

- [ ] **Step 3: Sprint loop logic + judgment rules**

Continue the SKILL.md with the sprint loop:

```
For each sprint in plan.md:
  1. harness-contract Agent → docs/harness/contracts/sprint-N.md
  2. retry_count = 0, pivot_count = 0

  SPRINT_LOOP:
  3. harness-generator Agent (input: contract + previous feedback if retry)
     → docs/harness/handoff/sprint-N-gen.md + Git commit
  4. harness-evaluator Agent (input: contract + handoff)
     → docs/harness/feedback/sprint-N-eval.md
  5. Parse evaluator judgment (read ## 판정 section):
     - PASS → run review Agent (gstack or fallback), then next sprint
     - RETRY → retry_count++
       - if retry_count <= max_retries:
         - Check trend: compare FAIL count with previous iteration
           - FAIL count same/increasing → invoke investigate (gstack) or systematic-debugging fallback
         - goto SPRINT_LOOP with feedback
       - else → PIVOT, pivot_count++
     - PIVOT → pivot_count++
       - if pivot_count <= max_pivots: goto SPRINT_LOOP with pivot direction
       - else → ESCALATE
     - ESCALATE → log issue to docs/harness/feedback/sprint-N-escalated.md, continue to next sprint

  6. After review Agent completes:
     - If auto-fix applied → re-run evaluator (re-evaluate loop)
     - If manual fix needed → feed back to generator

  7. Update state.md: current_sprint, last_commit, last_evaluator_feedback
  8. Git commit checkpoint
```

**StatusLine sentry (rate limit pre-detection):**
- Before each sprint iteration, check if rate limit usage is approaching threshold
- Read StatusLine JSON `rate_limits.five_hour.used_percentage` if accessible
- If `> 90%`: complete current sprint, then save state with `reason: preemptive_pause`, schedule resume

- [ ] **Step 4: Self-reset + QA + ship + state persistence**

Complete the SKILL.md with:

- **Self-reset logic**: every `self_reset_interval` sprints:
  1. Save state.md with `status: self_resetting`
  2. Git commit
  3. Bash: `claude -p "/harness --resume"` (background)
  4. End current skill execution

- **QA phase** (after all sprints complete):
  - Update state.md `current_phase: qa`
  - Dispatch harness-qa Agent
  - If bugs found: auto-fix + re-verify loop

- **Ship phase**:
  - Update state.md `current_phase: ship`
  - If gstack available: invoke `ship` skill
  - If not: fallback — run tests, `gh pr create`

- **Completion**:
  - Update state.md `status: completed`
  - Remove lock file
  - Git commit final state
  - Display summary: total sprints, pass rates, escalated issues

- [ ] **Step 5: Commit**

```bash
git add skills/harness/
git commit -m "feat: add main harness orchestrator skill"
```

---

### Task 12: Integration Testing

**Files:**
- No new files — verify existing skills work together

- [ ] **Step 1: Verify plugin loads**

```bash
cd /Users/jaewon/super-hype-harness
# Check all SKILL.md files have valid frontmatter
for f in $(find skills generators evaluators -name "SKILL.md"); do
  echo "--- $f ---"
  head -10 "$f"
  echo
done
```

Expected: Each file has valid `---` delimited YAML frontmatter with name and description.

- [ ] **Step 2: Verify plugin.json is valid JSON**

```bash
cat .claude-plugin/plugin.json | jq .
```

Expected: Valid JSON output with name, description, version.

- [ ] **Step 3: Verify hook is executable**

```bash
ls -la hooks/stop-failure-handler.sh
```

Expected: `-rwxr-xr-x` permissions.

- [ ] **Step 4: Verify directory structure matches spec**

```bash
find . -name "SKILL.md" -o -name "plugin.json" -o -name "*.sh" | sort
```

Expected: All files from the spec's directory structure are present.

- [ ] **Step 5: Commit any fixes**

```bash
git add -A
git commit -m "fix: integration testing fixes" # only if changes needed
```

---

### Task 13: Final README Polish & Release Prep

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README with actual skill list**

Verify `/harness` and `/harness-status` are the only user-invoked commands.
Add a "Skills Reference" section listing all skills with their type (user-invoked vs model-invoked).

- [ ] **Step 2: Add configuration section to README**

Document `docs/harness/config.md` options with defaults.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: polish README with skill reference and configuration"
```
