# Evaluation Criteria

> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed and the generator got detailed feedback on what went wrong." — Anthropic
> "Out of the box, Claude is a poor QA agent... would identify legitimate issues, then talk itself into deciding they weren't a big deal." — Anthropic

## Evaluation Approach

### Be Skeptical

Claude naturally skews positive when evaluating. Fight this tendency. If something looks questionable, it probably is. Do not talk yourself out of failures.

### Explore First, Judge Second

Before scoring:
1. **Navigate the entire app** — not just what the contract mentions
2. **Screenshot every page** and **Read the screenshots** — Claude can see images
3. **Study the implementation** — layout, flow, data persistence
4. **Then** evaluate criteria

### Screenshot Analysis Protocol

For every screenshot:
1. `agent-browser screenshot` → saves image file
2. `Read` the image file → visually analyze
3. Record observations in feedback

## Evaluation Dimensions

### 1. Contract Compliance (Hard gate — PASS/FAIL)

Each criterion has a **hard threshold**. If ANY ONE fails, the round FAILS.

### 2. Product Depth (Hard gate — PASS/FAIL)

<HARD-GATE>
Stub이 1개라도 있으면 FAIL. 하드코딩된 데이터, no-op 핸들러, 가짜 기능은 PASS가 될 수 없다.
</HARD-GATE>

- Stubs vs real features (hardcoded data, no-op handlers, "coming soon" placeholders)
- End-to-end completeness (create → persist → retrieve → display)
- Edge cases (empty state, errors, long text, rapid clicks)
- **If ANY feature is a stub → FAIL**

### 3. Design Quality (Hard gate for web apps — score 5 이하면 FAIL)

> "Does the design feel like a coherent whole rather than a collection of parts?"

- Score 5 이하면 FAIL — 최소한의 디자인 일관성 필요
- AI slop (제네릭 그라디언트, 기본 컴포넌트 그대로, 스톡 플레이스홀더) 발견 시 감점

### 4. Originality (Advisory, web apps)

> "Is there evidence of custom decisions, or is this template layouts, library defaults, and AI-generated patterns?"

### 5. Craft (Advisory)

> "Technical execution: typography hierarchy, spacing consistency, color harmony, contrast ratios."

### 6. Functionality (Hard gate — console error 있으면 FAIL)

<HARD-GATE>
Console에 에러가 있으면 FAIL. Warning은 허용, Error는 불가.
</HARD-GATE>

> "Usability independent of aesthetics. Can users understand what the interface does, find primary actions, and complete tasks without guessing?"

## QA Phases

The Evaluator runs in one of three phases, set by the orchestrator via `qa_phase` in the prompt.

### Phase: functional
Focus: Does every feature ACTUALLY WORK?

PASS requires ALL of:
- Every contract criterion verified with browser/CLI evidence (not code review)
- Zero stubs (setTimeout simulation, hardcoded data, no-op handlers)
- End-to-end data flow works (create → persist → refresh → exists)
- Generator self-assessment is IGNORED — verify independently

FAIL if ANY:
- Contract criterion fails
- Any stub/fake feature detected
- Any "코드에 구현 확인" used as evidence

### Phase: quality
Focus: Is the app polished and professional?

PASS requires ALL of:
- Design score 7+ (hierarchy, typography, spacing, color system)
- Zero AI slop (generic gradients, default MUI/Tailwind, stock text)
- All interaction states present (loading, error, success, empty)
- Zero console errors
- Responsive at 375px mobile viewport
- Keyboard navigation works for primary flows

FAIL if ANY:
- Design score below 7
- Console error exists
- Missing interaction state for any core feature
- AI slop detected (generic template look)

### Phase: edge_cases (Comprehensive Testing)
Focus: Parallel team testing — components, E2E, edge cases, DevTools, test generation.

**Web apps use Agent Team (6 teammates). CLI/library uses single agent.**

#### Teammate roles and PASS criteria:

**1. Component Tester**: Every UI component renders, interacts, state changes correctly.
**2. E2E Flow Tester**: Every user journey works end-to-end with data persistence.
**3. Edge Case Tester**: All adversarial scenarios pass:
  - Input abuse: empty, special chars, 500+ chars, emoji, RTL
  - Rapid interaction: double click, spam Enter, simultaneous actions
  - Navigation: back button, direct URL, refresh mid-action
  - Files: large (>10MB), zero-byte, wrong format
  - Empty states, boundary values (0/1/100), error recovery
**4. DevTools Inspector** (web apps): Lighthouse audit, console errors, network failures, memory, accessibility.
**5. Test Case Generator**: 50+ test cases documented in test-cases.md (unit/integration/e2e/edge).
**6. Adversarial Reviewer**: Reads all 5 outputs, challenges PASS judgments, finds untested gaps.

PASS requires: ALL 6 teammates PASS. Adversarial reviewer finds no additional issues.
FAIL if: Any teammate FAIL, or Adversarial finds untested scenarios.

## Judgment

### PASS
ALL of these must be true:
1. ALL contract criteria verified with evidence
2. ZERO stubs or fake features (Product Depth)
3. Design score > 5 (web apps)
4. ZERO console errors (Functionality)

### FAIL
ANY of the above fails. Detailed feedback with:
- What was tried
- What was expected
- What actually happened
- Steps to reproduce
- Concrete fix direction

<HARD-GATE>
9/10 점수를 주려면: 모든 기능이 end-to-end 동작, stub 없음, console error 없음, 디자인에 고유한 아이덴티티가 있어야 한다. 의심이 들면 점수를 낮춰라. "괜찮아 보이는데"는 9점이 아니라 7점이다.
</HARD-GATE>

## Scoring Guide (Advisory, 1-10)

> "Calibrated using few-shot examples with detailed score breakdowns."

- **9-10**: All criteria pass, features complete, design cohesive with identity, no console errors
- **7-8**: All criteria pass, minor rough edges, functional but some generic patterns
- **5-6**: Most criteria pass, some stubs or incomplete features, default component look
- **3-4**: Multiple criteria fail, significant gaps, broken layouts
- **1-2**: Most criteria fail, app barely functional

### Few-Shot Examples

**Score 9**: Calendar app — events create/persist/display, drag-to-reschedule works, custom color scheme with distinct identity, smooth animations, mobile responsive, zero console errors.

**Score 6**: Calendar app — events create and display, drag doesn't work, mobile breaks, Material UI defaults with no customization, 3 console warnings.

**Score 3**: Calendar app — grid renders, "create event" button does nothing, hardcoded sample data, no backend, default template look.
