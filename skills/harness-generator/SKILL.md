---
name: harness-generator
description: Builds the entire app from spec in one pass. Self-evaluates before handoff. On subsequent rounds, fixes issues from Evaluator feedback.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
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
7. **Read `generator_skills` from config.md** — for each listed skill, invoke `Skill("<skill-name>")` to load its guidelines. Follow these skills' patterns during implementation.
   - **IMPORTANT: If `generator_skills` is empty (`[]`), use these defaults by app_type:**
     - `web`: `tdd-workflow`, `frontend-design`, `vercel-react-best-practices`
     - `cli`: `tdd-workflow`
     - `library`: `tdd-workflow`
   - Invoke each skill via `Skill("<skill-name>")` before starting implementation.
   - `tdd-workflow`는 모든 app_type의 기본 스킬 — RED→GREEN→REFACTOR 사이클로 개발.

<HARD-GATE>
generator_skills에 스킬이 나열되어 있으면 반드시 Skill 도구로 각 스킬을 로드해야 합니다.
"프롬프트에 적혀있으니 알고 있다"는 증거가 아닙니다 — Skill() 호출 기록이 없으면 미사용으로 간주됩니다.
핸드오프의 Skills Used 섹션에 실제 로드한 스킬만 기록하세요. 로드하지 않은 스킬을 적으면 안 됩니다.
</HARD-GATE>

## Process

### Record Start Time

Update `docs/harness/state.md`:
- `build_started_at: [current ISO 8601 timestamp]`
- `current_round: N` (increment if round > 1)

### Round 1: Build Everything

Work through the spec feature by feature:
1. Start with project scaffolding and dev environment
2. **Set up test runner** (MANDATORY for web/cli apps):
   - Web (Next.js/React): `vitest` + `@testing-library/react`
   - Web (vanilla): `vitest`
   - CLI (Node): `vitest` or `jest`
   - CLI (Python): `pytest`
   - Add `test` script to package.json / pyproject.toml
3. **TDD로 기능 구현** — `tdd-workflow` 스킬의 RED→GREEN→REFACTOR 사이클:
   - 순수 함수(계산, 판정, 변환)는 **테스트 먼저 작성 → 구현 → 리팩터**
   - 예: 점수 계산, 게임오버 판정, 줄 클리어 로직, 상태 리듀서, 유효성 검증
   - Evaluator가 브라우저에서 검증하기 어려운 로직일수록 unit test가 더 중요
   - UI 컴포넌트 렌더링 테스트는 선택 (Evaluator가 브라우저로 확인)
   - `npm test`가 PASS하면 Evaluator는 해당 로직의 세부 수치를 브라우저에서 재검증하지 않음
5. If references exist, match their visual patterns and interactions
6. Commit frequently with descriptive messages
7. Use git for version control throughout

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
- **Tests pass**: run `npm test` (or equivalent), confirm all pass. 테스트 파일이 0개면 FAIL — Round 1에서 반드시 테스트 러너 설치 + unit test 작성이 필요함.
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

## Skills Used
- [skill name]: [how it was used — e.g., "tdd-workflow: RED→GREEN→REFACTOR로 engine 모듈 개발"]
- [skill name]: [usage description]
- Built-in only (if no external skills loaded)

## Test Results
- `npm test` exit code: [0 or 1]
- Total: [N] tests, [N] passed, [N] failed
- Unit test로 검증 완료된 contract 기준: [C07, C10, C12, ...]
- 실패한 테스트: [목록 또는 "없음"]

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
