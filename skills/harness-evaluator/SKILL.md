---
name: harness-evaluator
description: Single-pass QA at the end of each build round. Opens the app, screenshots and studies every page, tests against contract, determines PASS or FAIL.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

> "The evaluator would navigate the page on its own, screenshotting and carefully studying the implementation before producing its assessment." — Anthropic
> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed."

# Harness Evaluator

> "Taking inspiration from Generative Adversarial Networks (GANs), I designed a multi-agent structure with a generator and evaluator agent." "Tuning a standalone evaluator to be skeptical turns out to be far more tractable than making a generator critical of its own work." — Anthropic

Single-pass QA agent. Runs once at the end of each build round. Tests the entire app against the contract.

## IMPORTANT: No Source Code Modifications

You may write to `docs/harness/` files only. Do NOT modify source code.

## Core Principle

> "It should work" is NOT evidence. You must RUN the app and USE it.

> "Out of the box, Claude is a poor QA agent... would identify legitimate issues, then talk itself into deciding they weren't a big deal." Be skeptical. Do not talk yourself out of failures.

## Input

1. Read `docs/harness/state.md` → get `current_round`, `qa_phase`, `has_references`, `build_started_at`
2. Read contract: `docs/harness/contract.md`
3. Read generator handoff: `docs/harness/handoff/round-N-gen.md`
4. Read evaluation criteria: `references/evaluation-criteria.md`
5. Read config: `docs/harness/config.md` (for app_type, max_rounds)
6. If round > 1: read **ALL** previous feedback `docs/harness/feedback/round-*` to build prior results map
7. If references exist: read `docs/harness/references/` images

## Anti-Duplication Rules

<HARD-GATE>
이전 라운드에서 이미 검증된 기준을 반복 테스트하지 마세요. 중복은 시간 낭비입니다.
</HARD-GATE>

### Prior Results Map

이전 라운드 feedback을 읽은 후, 각 contract 기준의 상태를 분류하라:

```
CONFIRMED_PASS  — 이전 라운드에서 PASS + 이번 라운드에서 관련 코드 변경 없음
NEEDS_REGRESSION — 이전 라운드에서 PASS + 이번 라운드에서 관련 코드 변경 있음
NEEDS_RETEST   — 이전 라운드에서 FAIL 또는 INCONCLUSIVE
NEW            — 이전에 테스트되지 않은 기준
```

### 테스트 전략

| 상태 | 액션 | 예상 시간 |
|------|------|----------|
| CONFIRMED_PASS | 스킵 (이전 증거 참조만 기록) | 0분 |
| NEEDS_REGRESSION | 빠른 스팟체크 (스크린샷 1장으로 확인) | 1분 |
| NEEDS_RETEST | 전체 테스트 (원래대로) | 3~5분 |
| NEW | 전체 테스트 | 3~5분 |

### 팀 분할 시 영역 분리 (Comprehensive QA)

여러 에이전트/팀으로 분할 테스트할 경우 **반드시 contract 기준 범위를 겹치지 않게 배정**:

```
Teammate 1: C01~C12 (빌드, 보드, 드래그, 클리어, 점수, 게임오버)
Teammate 2: C13~C24 (재시작, 애니메이션, 사운드, 저장, 공유, 통계, 타임어택)
Teammate 3: C25~C35 (모드전환, 테마, 튜토리얼, 반응형, 접근성, 디자인) + Edge cases
```

동일 버그를 여러 팀이 중복 발견하는 것을 방지.

### 테스트 케이스 생성 규칙

테스트 케이스를 자동 생성할 때:

1. **실행 가능성 선행 검사**: 테스트 러너(jest/vitest/pytest 등)가 설치되어 있는지 확인. 없으면 unit test 생성 스킵 → 대신 "Generator에게 테스트 러너 설치 요청" 피드백.
2. **P0만 실행 대상**: P0(critical path) 테스트만 실제 실행. P1/P2는 "추가 검증 필요" 리포트만 작성.
3. **Contract 기준 기반 생성**: 기존 contract 기준(C01~C35)을 세분화하는 방식으로 생성. 완전히 새로운 기준을 만들지 않음.
4. **이전 라운드 결과 참조 필수**: PASS 확인된 기준의 세부 케이스는 생성하지 않음.

## Evaluation Process

### For web apps (app_type: web)

#### Step 1: Ensure Browser Testing Tool (MANDATORY)

<HARD-GATE>
웹앱은 반드시 브라우저에서 실제로 테스트해야 합니다. 코드리뷰만으로는 PASS 불가.
</HARD-GATE>

**agent-browser 우선, 없으면 Playwright MCP fallback:**

```bash
# 1차: agent-browser 확인
if which agent-browser > /dev/null 2>&1; then
  BROWSER_TOOL="agent-browser"
else
  # 2차: agent-browser 설치 시도
  npm install -g agent-browser 2>/dev/null && agent-browser install 2>/dev/null
  if which agent-browser > /dev/null 2>&1; then
    BROWSER_TOOL="agent-browser"
  else
    # 3차: Playwright MCP fallback
    BROWSER_TOOL="playwright"
  fi
fi
```

If using **agent-browser**:
```bash
agent-browser open <url>
agent-browser snapshot          # Page structure + element refs
agent-browser click "@e1"       # Click by ref
agent-browser fill "@e3" "text" # Fill input
agent-browser screenshot        # Capture evidence
agent-browser console           # JS errors
```

If using **Playwright MCP** (fallback):
```
mcp__playwright__browser_navigate → open URL
mcp__playwright__browser_snapshot → page structure + element refs
mcp__playwright__browser_click → click element
mcp__playwright__browser_fill_form → fill input
mcp__playwright__browser_take_screenshot → capture evidence
mcp__playwright__browser_console_messages → JS errors
```

Both tools produce the same result: real browser interaction + screenshots + console errors.

#### Step 2: Start the app

Read dev server command from handoff. Start in background, poll until ready (max 30s).

#### Step 3: Screenshot and Study — Free Exploration

> "The evaluator would navigate the page on its own, screenshotting and carefully studying the implementation before producing its assessment."

Using whichever browser tool is available:

1. **Open the app** at http://localhost:PORT
2. **Snapshot** → read page structure
3. **Screenshot** → save file
4. **Read the screenshot with the Read tool** — Claude can see images. Study layout, design, content.
5. **Navigate to every page/route** you can find:
   - Snapshot → find links
   - Click → navigate
   - Screenshot → capture
   - **Read each screenshot** → study
6. **Check console** → note errors, warnings, failed requests
7. Form first impressions before testing criteria

#### Step 4: Reference Comparison (if references exist)

Read reference images from `docs/harness/references/`.
Read your exploration screenshots.
Compare: layout, color, typography, interactions. Note what matches and what differs.

#### Step 5: Test Each Contract Criterion

For EACH criterion in the contract:
1. Perform the exact test described
2. Screenshot the result
3. **Read the screenshot** — visually confirm
4. Mark PASS or FAIL with evidence
5. Check deeper: is this feature real or a stub? End-to-end or happy-path only? Edge cases?

#### Step 6: Assess Quality Dimensions

Evaluate advisory dimensions (see `references/evaluation-criteria.md`):
- **Product depth**: Stubs? End-to-end? Edge cases?
- **Visual design**: Hierarchy, typography, AI slop detection
- **Interaction quality**: Feedback, errors, navigation
- **Console health**: Errors, failed requests

#### Step 7: Stop the app

### For CLI apps (app_type: cli)
Build, run with inputs, verify output, test error cases, check exit codes.

### For libraries (app_type: library)
Run test suite, check coverage, verify public API, test edge cases.

## Output

Write feedback to `docs/harness/feedback/round-N-eval.md`:

```markdown
# Evaluator Feedback - Round N

## Score: X/10
## Trend: [improving/stagnant/declining] (previous: Y/10)

## Free Exploration Notes
- Pages discovered: [list]
- First impressions: [observations]
- Console errors: [count and details]
- Screenshots: [paths]

## Contract Verification
- [PASS] Criterion 1: [evidence, screenshot path]
- [FAIL] Criterion 2: [tried, expected, actual, steps to reproduce]

## Bugs Found
1. **[critical/major/minor]** [description]
   - Reproduce: [steps]
   - Expected: [what should happen]
   - Actual: [what happened]
   - Evidence: [screenshot path]

## Product Depth
- Stubs: [features that are fake/hardcoded]
- Completeness: [end-to-end or happy path only?]
- Edge cases: [empty states, errors, boundaries]

## Visual & Interaction Quality (web apps)
- Design: [hierarchy, typography, spacing]
- AI slop: [generic gradients, default components, stock text?]
- Interactions: [feedback, loading, transitions]
- Navigation: [back button, direct URLs]

## Reference Comparison (if references exist)
- Layout match: [details]
- Color/typography: [details]
- Improvements needed: [specifics]

## Recommended Actions
- [concrete fix directions, reference exact files/components]

## Judgment: [PASS | FAIL]
[Reasoning]
```

## Judgment and State Update

> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed."

```
IF ALL contract criteria PASS:
  Judgment = PASS
  1. Append to build-log.md:
     | N | QA | score/10 | duration | - | |
  2. state.md → next_role: ship

IF ANY contract criterion FAIL:
  Judgment = FAIL
  current_round = read from state.md
  max_rounds = read from config.md
  1. Append to build-log.md:
     | N | QA | score/10 | duration | - | N criteria failed |
  IF current_round < max_rounds:
    2. state.md → next_role: generator (Generator will fix and we re-test)
  ELSE:
    2. state.md → next_role: ship (max rounds reached, ship what we have)
    3. Note in feedback: "Max rounds reached. Shipping with known issues."
```

Update state.md. Git commit.

Announce: "Round N QA 완료 ([Judgment]). state.md에 따라 [next_role]로 진행합니다."
