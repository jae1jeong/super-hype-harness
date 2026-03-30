---
name: harness
description: Long-running app development harness. Agent subprocess per phase (context reset) + Build/QA rounds. Config-based skill whitelist enforcement.
argument-hint: <app description> [--resume] [--no-auto-resume] [--status] [--ref <url-or-image>...]
allowed-tools: [Agent, Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch, TaskCreate, TaskUpdate]
---

> Harness architecture from Anthropic's blog. Agent subprocesses for context reset. Build/QA rounds, not sprints. File-based handoff between phases.

# Super Hype Harness

Each phase runs as an **Agent subprocess** (fresh context). The orchestrator dispatches agents, reads their file output, and decides the next step. Brainstorm runs in the main session (user interaction needed). All communication via handoff files.

## Skill Whitelist Enforcement

<HARD-GATE>
Sub-agents may ONLY use skills listed in `config.skills`. If a skill is not listed, use the built-in pattern instead. External skills MUST NOT chain to other skills (e.g., brainstorm skill must NOT invoke writing-plans or subagent-driven-development). The only valid output from any phase is the designated handoff file.
</HARD-GATE>

When dispatching any Agent, include this instruction in the prompt:
```
SKILL RESTRICTION: You may ONLY use these skills: [list from config.skills].
You MUST NOT invoke any other skill. You MUST NOT chain to implementation skills.
Your ONLY output is the designated handoff file.
```

## Arguments

Parse `$ARGUMENTS` for:
- `--resume` -> read state.md, continue from pause point
- `--status` -> invoke harness-status skill, then stop
- `--no-auto-resume` -> set auto_resume: false for this run
- `--ref <url-or-image>` -> reference material (repeatable)
- Everything else -> treat as the app description

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
agent-browser screenshot   # -> docs/harness/references/ref-N-home.png
agent-browser snapshot     # -> docs/harness/references/ref-N-snapshot.md
```
Navigate 2-3 key pages and screenshot each. Then close.

**If image file:**
Copy to `docs/harness/references/ref-N.<ext>`.

Record all references in `docs/harness/references/index.md`.

### 3. Skill Onboarding (first run only)

If config.md does not exist, scan for installed skills and present choices per category via AskUserQuestion.

**Scan:** Check which skills are accessible: office-hours, plan-ceo-review, plan-eng-review, plan-design-review, browse, review, investigate, ship, qa, design-review, superpowers:brainstorming, superpowers:test-driven-development, superpowers:systematic-debugging.

**4 questions** (only show detected skills + built-in option):

1. **Planning**: office-hours / superpowers:brainstorming / Built-in
2. **Review**: plan-ceo-review + plan-eng-review / Built-in checklist
3. **QA**: browse (gstack) / Built-in (agent-browser)
4. **Ship**: ship (gstack) / Built-in (gh pr create)

### 4. Config (docs/harness/config.md)

```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
max_rounds: 5
app_type: web
has_references: false

# Skill whitelist: only these skills are allowed. Empty = built-in only.
skills:
  brainstorm:
  ceo_review:
  eng_review:
  design_review:
  evaluate_qa:
  debug:
  code_review:
  ship:

# Generator reference skills (web apps)
generator_skills:
  - frontend-design
  - vercel-react-best-practices
```

### 5. Build Log (docs/harness/build-log.md)

```markdown
# Build Log

| Round | Phase | Score | Duration | Notes |
|-------|-------|-------|----------|-------|
```

### 6. State (docs/harness/state.md)

```yaml
---
status: running
paused_at:
resume_after:
resume_attempts: 0
---
## Pipeline State
- project: [from app description]
- spec:
- current_phase: brainstorm
- current_round: 0
- last_commit:
- last_evaluator_feedback:
- config: docs/harness/config.md
- has_references: false
```

### 7. Lock + Git Commit bootstrap files.

## Phase 1: Brainstorm (Main Session)

<HARD-GATE>
Do NOT proceed to Phase 2 until a spec file exists in docs/harness/specs/.
</HARD-GATE>

<EXTERNAL-SKILL-BOUNDARY>
If using an external brainstorm skill (config.skills.brainstorm), it MUST NOT chain to writing-plans, executing-plans, subagent-driven-development, or any implementation skill. If the skill attempts to chain, STOP it and extract only the spec output.
</EXTERNAL-SKILL-BOUNDARY>

Check `config.skills.brainstorm`:
- If set: invoke `Skill(config.skills.brainstorm)` with the app description. After it completes, verify output is a spec file ONLY. If it generated code or plans, discard everything except the spec.
- If empty: Read `skills/harness-brainstorm/SKILL.md` and follow its instructions directly.

Output: `docs/harness/specs/YYYY-MM-DD-<name>-spec.md`
Update state.md: `current_phase: review`. Git commit.

## Phase 2: Review (Agent Subprocesses)

<HARD-GATE>
Do NOT proceed to Phase 3 until all reviews pass.
</HARD-GATE>

### 2a. CEO Review

Dispatch Agent subprocess:
- If `config.skills.ceo_review` set: Agent prompt includes `Skill("config.skills.ceo_review")` instruction + SKILL RESTRICTION
- If empty: Agent performs built-in checklist:
  - MVP scoped right? Features over/under-scoped? Tech stack realistic? Missing features? Ambition level?

Parse result: scope issues -> return to Phase 1. Approved -> continue.

### 2b. Design Review (web only)

Skip if app_type is not web.

Dispatch Agent subprocess:
- If `config.skills.design_review` set: Agent uses that skill + SKILL RESTRICTION
- If empty: Built-in checklist: information hierarchy, interaction states, responsive, accessibility

Parse result: issues -> revise spec. Approved -> continue.

### 2c. Engineering Review

Dispatch Agent subprocess:
- If `config.skills.eng_review` set: Agent uses that skill + SKILL RESTRICTION
- If empty: Built-in checklist: data model, API design, error handling, security, performance

Parse result: tech change needed -> revise. Architecture issue -> Phase 1. Approved -> continue.

Update state.md: `current_phase: plan`. Git commit.

## Phase 3: Plan (Agent Subprocess)

Dispatch Agent with `skills/harness-planner/SKILL.md`:
- Input: reviewed spec + references (if any)
- Output: `docs/harness/plans/YYYY-MM-DD-plan.md`
- Update state.md: plan path. Git commit.

## Phase 4: Contract Negotiation (Agent Subprocess)

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal."

Dispatch Agent to negotiate contract:
1. Read spec + plan
2. Generator role: propose contract (what to build, how to verify)
3. Evaluator role: review contract (specific enough? machine-verifiable? edge cases?)
4. Iterate until agreed
5. Output: `docs/harness/contract.md`

Update state.md: `current_phase: build`. Git commit.

## Phase 5: Build -> QA Rounds

> "The Generator builds the ENTIRE app in one go. Then the Evaluator tests in a single pass."

```
for round in 1..max_rounds:

  ## Build
  Dispatch Generator Agent:
    - Read: contract.md + previous feedback (if round > 1) + generator profile + generator_skills
    - SKILL RESTRICTION applied
    - Output: code + docs/harness/handoff/round-N-gen.md + Git commits
    - Log to build-log.md: round, "Build", duration

  ## QA (Evaluator)
  Dispatch Evaluator Agent:
    - Read: contract.md + handoff + evaluator profile + references
    - SKILL RESTRICTION applied
    - For web apps: agent-browser REQUIRED (Playwright MCP fallback)
    - Explore First, Judge Second
    - Screenshot + Read for visual analysis
    - 5 dimensions: Contract, Product Depth, Visual, Interaction, Code
    - AI slop detection + Stub detection
    - "Be skeptical" — distrust Generator claims
    - Output: docs/harness/feedback/round-N-eval.md (PASS/FAIL + score)
    - Log to build-log.md: round, "QA", score, duration

  ## Judgment
  Read feedback -> parse PASS/FAIL:
    PASS -> break loop, go to Ship
    FAIL -> continue to next round (Generator gets feedback)

  if round == max_rounds and still FAIL:
    Log "max rounds reached" and proceed to Ship anyway
```

## Phase 6: Ship

Check `config.skills.ship`:
- If set: Dispatch Agent with that skill + SKILL RESTRICTION
- If empty: Built-in:
  1. Run test suite
  2. `gh pr create` with summary
  3. Display PR URL

Display final summary with build-log.md table:
```
Pipeline complete!
Project: [name]
Build rounds: N
Total duration: [sum]
QA: [PASS/FAIL]
PR: [URL]

Build Log:
| Round | Phase | Score | Duration |
|-------|-------|-------|----------|
| ...   | ...   | ...   | ...      |
```

Update state.md: `status: completed`. Remove lock. Git commit.

## Rate Limit Handling

StopFailure hook handles rate limits: pauses state.md, schedules resume via `at` command.
Resume reads state.md and continues from current_phase + current_round.
Exponential backoff: 30min -> 1h -> 2h if still limited.

## Context Reset Strategy

Each Agent subprocess starts with fresh context. The orchestrator's context contains ONLY:
- This SKILL.md (~300 lines)
- config.md (~30 lines)
- state.md (~15 lines)
- File paths and judgment decisions

Brainstorm runs in main session but its output (spec.md) is the handoff. After brainstorm, all subsequent phases are Agent subprocesses that read/write files. The orchestrator never accumulates conversation history from sub-agents — it only reads their file outputs.
