# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2026-04-03

### Added
- **`--rounds <N>` 파라미터** — 각 QA 페이즈별 최대 라운드 수 조절 (기본 10, 0=무제한). 제한 도달 시 `[MAX_ROUNDS reached]` 기록 후 다음 페이즈로 강제 진행
- **Config Validation (4b)** — config.md 생성 직후 `tdd-workflow` 등 필수 스킬 존재 검증. 누락 시 자동 추가 + pipeline-log에 `[AUTO-FIX]` 기록
- **Handoff Test Results 검증** — Round 1 핸드오프에서 테스트 파일 0개면 REJECT + re-dispatch
- **Contract Unit Test HARD-GATE** — T1(테스트 러너 설치), T2(핵심 로직 unit test) 기준 필수 포함
- **`/harness-remove-config` 스킬** — 구버전 config.md 삭제. 다음 `/harness` 실행 시 최신 템플릿으로 재생성

### Fixed
- **Generator Self-Evaluate 테스트 탈출구 제거** — "if they exist" 조건 삭제. 테스트 파일 0개 = FAIL
- **README.ko.md 최신화** — 3-Phase QA, Agent subprocess, Skills Reference 테이블, screenshots 디렉토리 등 영어 README과 동기화

### Changed
- README에 웹 특화 플러그인 명시 (agent-browser + Playwright 기반 QA)
- Claude Max $100/월 플랜 참고사항 추가 (~5라운드/~2시간에서 레이트 리밋)
- `max_rounds` 기본값: 10

## [0.8.2] - 2026-04-02

### Added
- **회고 스킬 P9: 테스트 케이스 중복 검사** — Teammate 간 중복 테스트 식별 체크리스트, 분석 방법론(완전 중복/부분 중복/의도적 교차검증 분류), 중복 비율 20% 기준, 보고서 템플릿 행 추가

## [0.8.1] - 2026-04-02

### Fixed
- **generator_skills 빈 배열 버그** — config.md에 `generator_skills: []`로 생성되면 Generator가 스킬 없이 빌드하는 문제
  - harness-generator: 빈 배열 + web app일 때 `frontend-design`, `vercel-react-best-practices` 자동 폴백
  - harness (bootstrap): config 생성 시 빈 배열 금지 경고 + app_type별 기본값 명시
- **Evaluator QA 중복 제거 + 회귀 테스트 강화**
  - Prior Results Map 도입 (NEEDS_RETEST / NEEDS_REGRESSION / STABLE_PASS / NEW)
  - 모든 기준을 매 라운드 전부 테스트하되, 우선순위로 실행 순서만 조절
  - "빠른 스팟체크"나 "스킵" 금지 — 회귀 버그는 변경하지 않은 코드에서도 발생
  - 팀 분할 시 contract 기준 범위 겹침 금지
  - 테스트 케이스 계층 중복 금지 (같은 함수를 unit+integration+e2e로 반복 생성 방지)

### Added
- **harness-retro 스킬** — 하네스로 만든 프로젝트의 회고 스킬
  - 실행 검증: 빌드, 실행, 핵심 기능 스팟체크
  - Anthropic 원문 8가지 핵심 원칙 대비 파이프라인 충실도 분석
  - README 상태 검증 및 교체 초안 자동 생성
  - Keep / Improve / Try 회고 보고서 출력
- **Generator에 테스트 러너 설치 + unit test 작성 의무화** — Round 1 빌드 시 vitest/jest/pytest 설정 및 핵심 로직 unit test 포함

## [0.8.0] - 2026-04-01

### Added
- **Pipeline Log (`pipeline-log.md`)** — 에이전트 디스패치, 스킬 사용, 오케스트레이터 판단을 타임스탬프와 함께 상세 기록
  - Actor/Event/Skills Used/Duration/Details 컬럼
  - 모든 페이즈에서 dispatch/complete/judgment/phase-transition 이벤트 기록
- **Generator/Evaluator 스킬 강제 로드** — `allowed-tools`에 `Skill` 추가 + HARD-GATE로 Skill() 호출 강제
  - generator_skills/evaluator_skills에 나열된 스킬을 반드시 Skill 도구로 로드
  - 핸드오프의 "Skills Used" 섹션 비어있으면 오케스트레이터가 WARN + 재디스패치
- **`web-design-guidelines` 빌트인 적용** — 웹앱 Evaluator가 디자인 QA 시 자동 로드
  - config.md에 `evaluator_skills` 섹션 추가
- **QA 테스트 케이스 실행 요약** — Phase 5.3 팀 완료 후 `round-N-test-summary.md` 생성
  - 카테고리별 Generated/Executed/PASS/FAIL 테이블
  - Adversarial 추가 케이스 + 미실행 케이스 목록
- **에이전트 팀 per-teammate 로깅** — 각 Teammate output footer에 Tools & Skills Used + 테스트 케이스 수 기록
- **`/harness-status --log`** — pipeline-log 최근 활동 + 스킬 사용 요약 표시
- **`/harness-status --tests`** — 테스트 케이스 실행 현황 표시

### Fixed
- **Generator/Evaluator `allowed-tools`에 `Skill` 누락** — 서브에이전트가 스킬을 호출할 수 없었던 근본 버그 수정

## [0.7.1] - 2026-04-01

### Fixed
- **스크린샷 저장 경로 통일** — 라운드별 `docs/harness/screenshots/round-N/` 디렉토리에 저장
  - 파일명 규칙: `explore-{page}.png`, `criterion-{n}.png`, `edge-{scenario}.png`, `devtools-{type}.png`
  - Evaluator, browser-qa evaluator, 오케스트레이터 Bootstrap 모두 통일
  - README Pipeline Output에 screenshots/ 추가

## [0.7.0] - 2026-04-01

### Added
- **`/harness-release` 스킬** — 버전 범프, CHANGELOG 생성, 태그, push, GitHub Release를 자동화
  - `patch` / `minor` / `major` + `--dry-run` 지원
  - 코드 diff 분석으로 커밋 메시지보다 정확한 CHANGELOG 생성
  - README/README.ko.md 동기화 체크
- **CEO Review 범위 확장 HARD-GATE** — "작게 만들자" 축소 경향 방지, 야심찬 제품을 위한 범위 확장 체크
- **Agent Team 케이스 전달 구조** — Test Case Generator가 먼저 실행 → 100+ 케이스를 Teammate 1-4에게 SendMessage로 전달
- **Adversarial Reviewer 강화** — 실행 안 된 케이스 식별 + PASS 증거 없으면 FAIL 처리

## [0.6.0] - 2026-04-01

### Added
- **3단계 심화 QA** — 단일 QA 루프를 3-phase progressive QA로 교체
- **Phase 5.3 Agent Team** — 웹앱 테스트를 6개 병렬 Agent로 확장:
  - Component Tester: 모든 UI 컴포넌트 단위 테스트
  - E2E Flow Tester: 사용자 여정 전체 테스트
  - Edge Case Tester: 입력 남용, 연타, 네비게이션, 경계값
  - DevTools Inspector: Lighthouse, console, network, memory, 접근성 감사
  - Test Case Generator: 50+ 테스트 케이스 문서 자동 생성
  - Adversarial Reviewer: 다른 5개 결과를 교차 검증, 빠진 시나리오 탐지
- **Chrome DevTools MCP 통합** — console error, network 실패, Lighthouse 감사, 메모리 스냅샷
  - Phase 1 (Functional): Contract 기준 실제 동작 확인 + stub/가짜 기능 제로
  - Phase 2 (Quality): 디자인 7+, console error 0, 반응형, 인터랙션 상태, 접근성
  - Phase 3 (Edge Cases): 입력 남용, 연타, 뒤로가기, 대용량 파일, 경계값, 빈 상태, 에러 복구
- 각 Phase별 독립 Evaluator Agent (fresh context, 이전 Phase의 관대한 판정에 오염 안 됨)
- Build-log에 QA Phase 컬럼 추가
- evaluation-criteria.md에 qa_phase별 PASS/FAIL 기준 명세

### Changed
- Evaluator가 코드 리뷰로 PASS 주는 것 금지 (HARD-GATE 강화)
- Product Depth를 Advisory → Hard gate (stub 1개 = FAIL)
- Console error = FAIL (Hard gate)
- Evaluator에서 Edit 도구 제거
- Contract에 Evidence Requirement + Anti-Stub Criteria 강제
- agent-browser 우선 사용 HARD-GATE (Playwright MCP는 최후 fallback)
- 라운드 상한 제거 — PASS될 때까지 무제한 반복

### Fixed
- Evaluator가 Generator "38/38 DONE" 자체 평가를 그대로 믿는 문제
- "Playwright 한계로 미수행"을 PASS로 인정하는 문제 → UNTESTED = FAIL

## [0.5.1] - 2026-03-31

### Fixed
- `max_rounds`, `max_retries`, `max_pivots` 상한 제거 — 원문 패턴대로 Evaluator PASS될 때까지 무제한 반복
- `vercel-react-best-practices`를 config.skills.frontend 기본값으로 추가

## [0.5.0] - 2026-03-30

### Changed (BREAKING)
- **Agent 서브프로세스 복원** — 각 phase가 독립 Agent에서 실행 (context reset)
  - v0.4.0의 단일 세션 Role Loop 제거
  - 오케스트레이터는 Agent 디스패치 + 파일 읽기 + 판정만 수행 (context 최소화)
  - Brainstorm만 메인 세션 (사용자 대화 필요)
- **Build/QA 라운드 유지** (v0.4.0에서 가져옴) — 스프린트 없이 전체 빌드 후 QA

### Added
- **스킬 화이트리스트 강제** — config.skills에 명시된 스킬만 서브에이전트가 사용 가능
- **EXTERNAL SKILL BOUNDARY** — 외부 스킬이 다른 스킬로 체이닝하는 것 차단 (brainstorm -> writing-plans 등)
- **SKILL RESTRICTION 프롬프트** — 모든 Agent 디스패치 시 허용 스킬 목록 명시
- v0.4.0의 모든 품질 개선 유지: agent-browser 강제, Playwright MCP fallback, 스크린샷 시각 분석, Explore First/Judge Second, 5개 평가 차원, AI slop/Stub 탐지, be skeptical, 하드 임계값 스코어링, 레퍼런스 시스템, 계약 협상, build-log.md

### Architecture
```
v0.3.0: Agent subprocess + Sprint Loop
v0.4.0: Single session + Build/QA rounds
v0.5.0: Agent subprocess + Build/QA rounds (best of both)
```

## [0.4.0] - 2026-03-29

### Changed (BREAKING)
- **Anthropic V2 아키텍처로 전면 전환** — 원문 최신 버전과 동일한 프로세스
  - 오케스트레이터 제거 → 파일 기반 핸드오프 + 역할 루프
  - **스프린트 제거** → 빌드→QA 라운드 방식 (Generator가 전체 빌드, Evaluator가 한 번에 테스트)
  - 하나의 연속 세션, Agent subprocess 없음, 자동 compaction 사용
  - sprint-log.md → build-log.md (라운드별 기록)
  - RETRY/PIVOT/ESCALATE → 단순 PASS/FAIL + 라운드 반복
- **계약 협상** — Generator가 제안, Evaluator가 리뷰, 합의할 때까지 반복
- **Planner에 frontend design skill 참조** — 비주얼 디자인 언어를 spec에 포함
- **Evaluator가 판단 + state.md 업데이트 소유**
- **QA가 Evaluator에 통합** — 별도 QA 단계 제거, Evaluator가 매 라운드 끝에 전체 테스트

### Added
- **레퍼런스 시스템** — `--ref <url-or-image>`로 참조 사이트/이미지 제공
- **스크린샷 시각 분석** — agent-browser screenshot 후 Read 도구로 이미지 열어 분석
- **하드 임계값 스코어링** + few-shot 캘리브레이션
- 평가 기준에 Anthropic 원문 직접 인용 (design quality, originality, craft, functionality)
- 평가 기준에 "be skeptical" 경고 — Claude가 자연적으로 긍정 편향되는 것 방지

## [0.3.2] - 2026-03-29

### Added
- 스프린트 로그 시스템 (`docs/harness/sprint-log.md`) — 스프린트별 상태, 점수, 리트라이, 소요시간 중앙 집중 기록
- Evaluator "Explore First, Judge Second" 패턴 — contract 테스트 전 앱 전체 자유 탐색 필수
- 5개 평가 차원: Contract Compliance, Product Depth, Visual Design Quality, Interaction Quality, Code Quality
- AI slop 탐지 (제네릭 그라디언트, 기본 컴포넌트 그대로, 스톡 플레이스홀더)
- Stub 탐지 (UI는 있지만 기능이 가짜/하드코딩된 경우)
- 평가 피드백에 Free Exploration Notes, Product Depth, Visual & Interaction Quality 섹션 추가
- 점수 가이드 (1-10) 추가

### Changed
- agent-browser가 웹앱 평가에서 필수로 변경 — curl fallback 제거, 미설치 시 자동 설치
- QA 스킬에서도 agent-browser fallback 제거
- `/harness-status` 출력을 sprint-log.md 기반 테이블로 변경
- 파이프라인 완료 요약에 총 소요시간, 총 리트라이 수 추가

## [0.3.1] - 2026-03-28

### Fixed
- 외부 brainstorm 스킬(superpowers:brainstorming 등)이 writing-plans → subagent-driven-development로 체이닝되면서 스프린트 루프(Contract → Generator → Evaluator)를 완전히 우회하는 치명적 버그 수정
- Phase 1에 EXTERNAL SKILL BOUNDARY 하드게이트 추가 — brainstorm 스킬이 implementation 스킬로 체이닝되는 것을 차단
- Phase 2에 PIPELINE INTEGRITY CHECK 추가 — spec 단계에서 코드가 생성되었는지 검증
- Phase 3에 MANDATORY SPRINT LOOP 하드게이트 추가 — 외부 execution 프레임워크로 대체 금지
- Sprint Checkpoint에 ARTIFACT VERIFICATION 추가 — contract/handoff/feedback 파일 존재 검증 후에만 다음 스프린트 진행

## [0.3.0] - 2026-03-27

### Added
- Skill onboarding: first run detects installed skills (gstack, superpowers) and lets user pick per category (planning, review, QA, ship)
- Per-category skill mapping in config.md (`skills:` section)
- Evaluator rewritten as user-perspective tester: opens app in browser via agent-browser, clicks through flows, finds bugs with screenshots
- Bug category guide for evaluator (functional, integration, UI/UX, edge cases)
- Codex CLI support via AGENTS.md
- StopFailure hook registered in plugin.json
- Korean README (README.ko.md)

### Changed
- Evaluator now tests the actual running app every sprint, not just code review
- agent-browser invocation fixed to correct package name and CLI commands
- README comprehensively rewritten with pipeline diagram, preset tables, output structure

## [0.2.0] - 2026-03-27

### Added
- marketplace.json for one-click install (`claude plugins marketplace add`)
- Codex CLI support via AGENTS.md

### Changed
- All external plugin dependencies removed (gstack, superpowers, dev plugin)
- Patterns internalized with credits to original projects
- Repository URL updated to jae1jeong/super-hype-harness

## [0.1.0] - 2026-03-26

### Added
- Initial implementation: 12 SKILL.md files
- Orchestrator with Brainstorm, Review, Plan, Sprint Loop, QA, Ship phases
- Generator-Evaluator GAN-inspired loop with RETRY/PIVOT/ESCALATE
- Rate limit auto-resume via StopFailure hook + exponential backoff
- Orchestrator self-reset every N sprints
- Custom generator/evaluator presets (default, frontend, browser-qa, design-qa)
- File-based handoff + Git commit checkpoints
- Design spec and implementation plan
