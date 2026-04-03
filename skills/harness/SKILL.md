---
name: harness
description: Long-running app development harness. Agent subprocess per phase (context reset) + Build/QA rounds. Config-based skill whitelist enforcement.
argument-hint: <app description> [--resume] [--no-auto-resume] [--status] [--rounds <N>] [--ref <url-or-image>...]
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
- `--rounds <N>` -> 각 QA 페이즈별 최대 라운드 수 (기본값: 무제한). config.md의 `max_rounds`에 저장
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
docs/harness/screenshots/
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
max_rounds: 10           # 각 QA 페이즈별 최대 라운드 수. 0 = 무제한 (PASS까지 반복)
generator: default
evaluator: default
browser_evaluator: browser-qa
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
  frontend: vercel-react-best-practices  # web app Generator가 프론트엔드 코딩 시 참조
  design_guidelines: web-design-guidelines  # web app Evaluator가 디자인 QA 시 참조 (built-in)

# Generator가 빌드 시 참조할 스킬
# IMPORTANT: app_type: web이면 아래 기본값을 반드시 채워서 생성할 것.
# 빈 배열([])로 생성하면 Generator가 스킬 없이 빌드하게 됨.
generator_skills:     # app_type: web 기본값 ↓
  - tdd-workflow               # TDD: RED→GREEN→REFACTOR, 테스트 피라미드 기반 개발
  - frontend-design            # Anthropic frontend design skill
  - vercel-react-best-practices  # Vercel/React best practices
# app_type: cli 기본값:
#   - tdd-workflow
# app_type: library 기본값:
#   - tdd-workflow

# Evaluator reference skills (web apps)
evaluator_skills:
  - web-design-guidelines
```

> **주의**: `generator_skills: []` (빈 배열)로 생성하지 마세요. web 앱이면 반드시 기본 스킬을 포함해야 합니다.

### 4b. Config Validation (MANDATORY)

config.md 생성 직후, 아래 필수 스킬이 `generator_skills`에 포함되어 있는지 검증:

| app_type | 필수 스킬 |
|----------|-----------|
| web | `tdd-workflow`, `frontend-design`, `vercel-react-best-practices` |
| cli | `tdd-workflow` |
| library | `tdd-workflow` |

**`tdd-workflow`는 모든 app_type에서 필수.** 누락 시 자동으로 추가하고 pipeline-log에 `[AUTO-FIX] tdd-workflow added to generator_skills` 기록.

### 5. Build Log (docs/harness/build-log.md)

```markdown
# Build Log

| Round | Phase | QA Phase | Score | Duration | Notes |
|-------|-------|----------|-------|----------|-------|
```

### 5b. Pipeline Log (docs/harness/pipeline-log.md)

서브에이전트 디스패치, 스킬 사용, 오케스트레이터 결정을 기록하는 상세 로그.

```markdown
# Pipeline Log

| Timestamp | Phase | Actor | Event | Skills Used | Duration | Details |
|-----------|-------|-------|-------|-------------|----------|---------|
```

**Actor**: `orchestrator`, `generator`, `evaluator`, `planner`, `contract`, `reviewer`, `team:teammate-N`
**Event**: `dispatch`, `complete`, `judgment`, `skill-load`, `retry`, `phase-transition`, `error`

로그 기록 규칙:
- 에이전트 디스패치 시: `dispatch` 이벤트 (어떤 프롬프트/설정으로 보냈는지)
- 에이전트 완료 시: `complete` 이벤트 (소요시간, 사용한 스킬 목록)
- 오케스트레이터 판단 시: `judgment` 이벤트 (PASS/FAIL, 다음 단계 결정 이유)
- 페이즈 전환 시: `phase-transition` 이벤트
- 에러/재시도 시: `error` 또는 `retry` 이벤트

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

## Pipeline Logging

모든 페이즈에서 아래 패턴으로 `docs/harness/pipeline-log.md`에 로그를 추가합니다.

### 에이전트 디스패치 시 (MANDATORY)
```bash
# 현재 시각 기록
START_TIME=$(date +%s)
```
pipeline-log.md에 append:
```
| [ISO timestamp] | [phase] | orchestrator | dispatch | - | - | [agent type], config: [설정 요약] |
```

### 에이전트 완료 시 (MANDATORY)
```bash
END_TIME=$(date +%s)
DURATION=$(( (END_TIME - START_TIME) / 60 ))m
```
에이전트 결과에서 사용된 스킬 목록을 읽고 pipeline-log.md에 append:
```
| [ISO timestamp] | [phase] | [actor] | complete | [skills list] | [duration] | [결과 요약] |
```

### 오케스트레이터 판단 시 (MANDATORY)
```
| [ISO timestamp] | [phase] | orchestrator | judgment | - | - | [PASS/FAIL], reason: [판단 근거], next: [다음 단계] |
```

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

**Log**: dispatch(brainstorm) → complete(brainstorm, skills used, duration)

Output: `docs/harness/specs/YYYY-MM-DD-<name>-spec.md`
Update state.md: `current_phase: review`. Git commit.
**Log**: phase-transition(brainstorm → review)

## Phase 2: Review (Agent Subprocesses)

<HARD-GATE>
Do NOT proceed to Phase 3 until all reviews pass.
</HARD-GATE>

### 2a. CEO Review

<HARD-GATE>
CEO Review의 목적은 범위를 줄이는 것이 아니라, 야심찬 제품을 만들기 위해 범위를 적절히 확장하는 것이다.
"작게 만들자"는 기본 성향을 경계하라. Anthropic 글에서 Planner는 1-4문장을 16개 기능으로 확장했다.
</HARD-GATE>

**Log**: dispatch(ceo_review)

Dispatch Agent subprocess:
- If `config.skills.ceo_review` set: Agent prompt includes `Skill("config.skills.ceo_review")` instruction + SKILL RESTRICTION
- If empty: Agent performs built-in review:

**범위 확장 체크 (축소가 아님):**
- 사용자가 말한 것보다 더 큰 제품이 숨어있지 않은가? ("일일 브리핑 앱"이 아니라 "개인 비서 AI"일 수 있다)
- 핵심 기능 외에 사용자가 "당연히 있을 거라 기대하는" 기능이 빠져있지 않은가?
- AI 통합 포인트가 충분한가? (Claude/LLM을 더 활용할 수 있는 곳은?)
- 경쟁 제품 대비 차별화 포인트가 명확한가?

**현실성 체크:**
- 기술 스택이 목표에 맞는가?
- MVP로 충분히 "와" 할 수 있는 수준인가? (너무 보수적이면 FAIL)
- 너무 야심차서 완성 불가능한 수준은 아닌가?

**판정:**
- "범위가 너무 작다 / 야심이 부족하다" → spec 확장 요청 후 Phase 1로
- "범위가 적절하고 야심차다" → continue
- "범위가 너무 커서 현실적이지 않다" → spec 축소 요청 후 Phase 1로

**Log**: complete(ceo_review, skills, duration) + judgment(review result, next step)

### 2b. Design Review (web only)

Skip if app_type is not web.

**Log**: dispatch(design_review)

Dispatch Agent subprocess:
- If `config.skills.design_review` set: Agent uses that skill + SKILL RESTRICTION
- If empty: Built-in checklist: information hierarchy, interaction states, responsive, accessibility

Parse result: issues -> revise spec. Approved -> continue.

**Log**: complete(design_review, skills, duration) + judgment(review result)

### 2c. Engineering Review

**Log**: dispatch(eng_review)

Dispatch Agent subprocess:
- If `config.skills.eng_review` set: Agent uses that skill + SKILL RESTRICTION
- If empty: Built-in checklist: data model, API design, error handling, security, performance

Parse result: tech change needed -> revise. Architecture issue -> Phase 1. Approved -> continue.

**Log**: complete(eng_review, skills, duration) + judgment(review result)

Update state.md: `current_phase: plan`. Git commit.
**Log**: phase-transition(review → plan)

## Phase 3: Plan (Agent Subprocess)

**Log**: dispatch(planner)

Dispatch Agent with `skills/harness-planner/SKILL.md`:
- Input: reviewed spec + references (if any)
- Output: `docs/harness/plans/YYYY-MM-DD-plan.md`
- Update state.md: plan path. Git commit.

**Log**: complete(planner, skills, duration) + phase-transition(plan → contract)

## Phase 4: Contract Negotiation (Agent Subprocess)

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal."

**Log**: dispatch(contract)

Dispatch Agent to negotiate contract:
1. Read spec + plan
2. Generator role: propose contract (what to build, how to verify)
3. Evaluator role: review contract (specific enough? machine-verifiable? edge cases?)
4. Iterate until agreed
5. Output: `docs/harness/contract.md`

**Log**: complete(contract, iteration count, duration)

Update state.md: `current_phase: build`. Git commit.
**Log**: phase-transition(contract → build)

## Phase 5: Build -> 3-Phase QA

> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed."

Three progressive phases. Each phase has its own PASS criteria. Generator fixes issues between rounds.

**라운드 제한**: `config.max_rounds > 0`이면 각 QA 페이즈에서 해당 횟수만큼만 라운드를 실행. 제한에 도달하면 현재 점수/상태로 다음 페이즈로 강제 진행하고, build-log에 `[MAX_ROUNDS reached]` 기록. `max_rounds: 0`이면 PASS까지 무제한 반복.

### Phase 5.1: Functional (기능 완성)

PASS criteria: ALL contract criteria verified with real evidence + ZERO stubs/fake features.

```
round = 1

LOOP (until Phase 5.1 PASS):

  ## Build
  **Log**: dispatch(generator, round=N)
  Dispatch Generator Agent:
    - Read: contract.md + previous feedback (if round > 1) + generator profile + generator_skills
    - SKILL RESTRICTION applied
    - **에이전트 프롬프트에 포함**: "완료 시 `docs/harness/handoff/round-N-gen.md`의 Skills Used 섹션에 로드한 스킬 목록을 기록하라"
    - Output: code + docs/harness/handoff/round-N-gen.md + Git commits
    - Log to build-log.md: round, "Build", duration

  ## Handoff Validation (MANDATORY)
  Read `docs/harness/handoff/round-N-gen.md`:

  **Skills Used 검증:**
  - If generator_skills are configured but Skills Used is empty or says "Built-in only" → **WARN** in pipeline-log and re-dispatch with explicit reminder
  - If Skills Used lists skills that weren't in generator_skills → **WARN** (unauthorized skill)

  **Test Results 검증 (Round 1 필수):**
  - Read handoff의 "Test Results" 섹션
  - 테스트 파일 0개 또는 `npm test` 미실행 → **REJECT**: "테스트 러너 설치 + unit test 작성 후 다시 핸드오프하라" 메시지와 함께 re-dispatch
  - pipeline-log에 `[REJECT] No tests found in Round 1 handoff` 기록

  **Log**: complete(generator, round=N, skills from handoff, duration)

  ## Functional QA (Evaluator Agent — fresh context)
  **Log**: dispatch(evaluator, round=N, qa_phase=functional)
  Dispatch Evaluator Agent with qa_phase: "functional":
    - For web apps: agent-browser REQUIRED (Playwright MCP fallback)
    - Test EVERY contract criterion by actually using the app
    - "코드에 구현 확인" is NOT evidence — must run and verify
    - Stub detection: setTimeout simulations, hardcoded data, no-op handlers = FAIL
    - End-to-end: create -> persist -> refresh -> still exists
    - Generator self-assessment ("38/38 DONE") must be IGNORED
    - **에이전트 프롬프트에 포함**: "완료 시 feedback 파일의 Tools & Skills Used 섹션에 사용한 브라우저 도구와 스킬을 기록하라"
    - Output: docs/harness/feedback/round-N-functional.md (PASS/FAIL + score)
    - Log to build-log.md
  **Log**: complete(evaluator, round=N, qa_phase=functional, skills/tools from feedback, duration)

  ## Judgment
  **Log**: judgment(functional, PASS/FAIL, score, reason, next step)
  PASS (zero FAIL criteria + zero stubs) -> Phase 5.2
  FAIL + max_rounds reached -> Phase 5.2 (강제 진행, build-log에 [MAX_ROUNDS reached] 기록)
  FAIL -> round += 1, Generator fixes, re-test
```

### Phase 5.2: Quality (품질 개선)

PASS criteria: Design score 7+, console error 0, all interaction states present.

```
LOOP (until Phase 5.2 PASS):

  ## Quality QA (Evaluator Agent — fresh context, different perspective)
  **Log**: dispatch(evaluator, round=N, qa_phase=quality)
  Dispatch Evaluator Agent with qa_phase: "quality":
    - Design consistency: hierarchy, typography, spacing, color system
    - AI slop detection: generic gradients, default components, stock placeholders
    - Interaction feedback: loading, error, success, empty states all present
    - Console: ZERO errors (warnings OK)
    - Responsive: test at mobile viewport (375px)
    - Accessibility: keyboard navigation works, contrast adequate
    - **에이전트 프롬프트에 포함**: "완료 시 feedback 파일의 Tools & Skills Used 섹션에 사용한 도구/스킬을 기록하라"
    - Output: docs/harness/feedback/round-N-quality.md (PASS/FAIL + score)
    - Log to build-log.md
  **Log**: complete(evaluator, round=N, qa_phase=quality, tools/skills, duration)

  ## Judgment
  **Log**: judgment(quality, PASS/FAIL, score, reason, next step)
  PASS (design 7+, console error 0, states present) -> Phase 5.3
  FAIL + max_rounds reached -> Phase 5.3 (강제 진행, build-log에 [MAX_ROUNDS reached] 기록)
  FAIL -> Generator fixes, re-test
```

### Phase 5.3: Comprehensive Testing (포괄적 테스트)

PASS criteria: ALL teammates PASS. Adversarial reviewer finds no additional issues.

> Inspired by OpenObserve's "Council of Sub Agents" — 8 specialized agents, 380 → 700+ tests.

**For web apps, use Agent Team (parallel). For CLI/library, use single Agent (sequential).**

```
## Web App: Agent Team (5 parallel testers + 1 reviewer)

**Log**: dispatch(team, round=N, qa_phase=comprehensive, teammates=6)

Dispatch Agent Team with 6 teammates:

  Teammate 1: Component Tester
    - List all UI components/pages from source code
    - For EACH component: render, interact, verify state changes
    - Test props/events/conditional rendering
    - Use agent-browser: open page → snapshot → click each interactive element → verify
    - **If web app**: load `web-design-guidelines` skill for design compliance checking
    - **Output footer에 포함**: Tools & Skills Used + 실행한 테스트 케이스 수 + PASS/FAIL 수
    - Output: docs/harness/feedback/round-N-components.md

  Teammate 2: E2E Flow Tester
    - Test every user journey from spec (signup → core feature → completion)
    - Use agent-browser for full flow: navigate → fill → submit → verify result
    - Test data persistence: create → navigate away → come back → still exists?
    - **Output footer에 포함**: Tools & Skills Used + 실행한 테스트 케이스 수 + PASS/FAIL 수
    - Output: docs/harness/feedback/round-N-e2e.md

  Teammate 3: Edge Case Tester
    - Input abuse: empty, special chars (< > " ' & /), 500+ chars, emoji, RTL
    - Rapid interaction: double click, spam Enter, simultaneous actions
    - Navigation: back button, direct URL, refresh mid-action, deep link
    - Files: large (>10MB), zero-byte, wrong format
    - Boundary: 0 items, 1 item, 100 items
    - Empty states: no data, all deleted, first-time user
    - Error recovery: after error, can user continue?
    - **Output footer에 포함**: Tools & Skills Used + 실행한 테스트 케이스 수 + PASS/FAIL 수
    - Output: docs/harness/feedback/round-N-edge.md

  Teammate 4: DevTools Inspector (web apps — uses Chrome DevTools MCP)
    - Console: capture ALL errors, warnings, failed requests
    - Network: check for failed API calls, slow requests (>3s), CORS errors
    - Performance: run Lighthouse audit, check Core Web Vitals
    - Memory: take memory snapshot, check for obvious leaks
    - Accessibility: run accessibility audit
    - Use tools: mcp__chrome-devtools__list_console_messages,
      mcp__chrome-devtools__list_network_requests,
      mcp__chrome-devtools__lighthouse_audit,
      mcp__chrome-devtools__take_memory_snapshot,
      mcp__chrome-devtools__performance_start_trace / stop_trace
    - **Output footer에 포함**: Tools & Skills Used + audit 결과 요약
    - Output: docs/harness/feedback/round-N-devtools.md

  Teammate 5: Test Case Generator (먼저 실행, 결과를 1-4에게 전달)
    - Analyze source code: components, routes, API endpoints, state management
    - Generate 100+ test cases: docs/harness/test-cases.md
    - Categories: unit, integration, e2e, edge case, performance
    - Format per case:
      | # | Category | Component | Action | Expected | Priority |
    - SendMessage to Teammate 1-4: "이 케이스들을 실행해주세요"
      - Component cases → Teammate 1
      - E2E flow cases → Teammate 2
      - Edge cases → Teammate 3
      - DevTools/performance cases → Teammate 4
    - Output: docs/harness/feedback/round-N-testcases.md + docs/harness/test-cases.md
    - 매 라운드마다 코드를 다시 분석해서 케이스 업데이트
    - **Output footer에 포함**: 총 생성 케이스 수 (카테고리별 breakdown)

  Teammate 6: Adversarial Reviewer (모든 결과가 나온 후 실행)
    - Read test-cases.md: "빠진 케이스가 있다" → 추가 케이스 생성
    - Read ALL 5 teammate outputs:
      - "PASS 줬는데 스크린샷 증거 없다" → FAIL 처리
      - "이 케이스 실행 안 했다" → FAIL 처리
      - "Teammate 2가 PASS인데 Teammate 1 결과와 모순" → 지적
    - test-cases.md의 케이스 중 실행되지 않은 것 식별
    - **Output footer에 포함**: 추가 생성한 케이스 수 + 발견된 모순/미실행 수
    - Output: docs/harness/feedback/round-N-adversarial.md

**Log**: complete(team, round=N, per-teammate: {name, duration, tools/skills used, test cases run/pass/fail})

## Test Case Summary Log (MANDATORY after team complete)
오케스트레이터가 팀 완료 후 pipeline-log.md에 테스트 케이스 요약을 기록:
```
| [timestamp] | build:5.3 | orchestrator | test-summary | - | - | Total: N cases, PASS: X, FAIL: Y, UNTESTED: Z. By category: component(N), e2e(N), edge(N), devtools(N). Adversarial additions: N |
```
또한 `docs/harness/test-cases.md`의 실행 결과를 `docs/harness/feedback/round-N-test-summary.md`에 통합 요약 작성:
```markdown
# Test Case Execution Summary - Round N

## Overview
- Total cases generated: [N]
- Executed: [N] / Skipped: [N]
- PASS: [N] / FAIL: [N]
- Adversarial additions: [N]

## By Category
| Category | Generated | Executed | PASS | FAIL |
|----------|-----------|----------|------|------|
| Component | N | N | N | N |
| E2E | N | N | N | N |
| Edge Case | N | N | N | N |
| Performance | N | N | N | N |

## Failed Cases
| # | Category | Component | Action | Expected | Actual | Teammate |
|---|----------|-----------|--------|----------|--------|----------|
...

## Unexecuted Cases (flagged by Adversarial)
...
```

## Team Lead Judgment
  **Log**: judgment(comprehensive, PASS/FAIL, details per teammate, next step)
  Read all 6 outputs:
    ALL teammates PASS + Adversarial finds nothing new → Phase 5.3 PASS → Ship
    ANY teammate FAIL or Adversarial finds issues + max_rounds reached → Ship (강제 진행, build-log에 [MAX_ROUNDS reached] 기록)
    ANY teammate FAIL or Adversarial finds issues → Generator fixes → re-run failed teammates

## CLI/Library: Single Agent (sequential)
  Dispatch Evaluator Agent with qa_phase: "edge_cases":
    - Run test suite with edge case inputs
    - Boundary values, error handling, invalid types
    - Generate test-cases.md
    - Output: docs/harness/feedback/round-N-edge.md
```

`max_rounds: 0`이면 무제한 반복. `max_rounds > 0`이면 각 페이즈별 해당 횟수에서 강제 진행.

## Phase 6: Ship

**Log**: dispatch(ship) + phase-transition(build → ship)

Check `config.skills.ship`:
- If set: Dispatch Agent with that skill + SKILL RESTRICTION
- If empty: Built-in:
  1. Run test suite
  2. `gh pr create` with summary
  3. Display PR URL

**Log**: complete(ship, duration) + pipeline-complete

Display final summary with build-log.md table + pipeline-log.md summary:
```
Pipeline complete!
Project: [name]
Build rounds: N
Total duration: [sum]
Functional QA: PASS (round N)
Quality QA: PASS (round N, score X/10)
Edge Case QA: PASS (round N)
PR: [URL]

Build Log:
| Round | Phase | QA Phase | Score | Duration | Notes |
|-------|-------|----------|-------|----------|-------|
| ...   | ...   | ...      | ...   | ...      | ...   |
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
