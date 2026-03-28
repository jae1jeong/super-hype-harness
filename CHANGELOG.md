# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-03-29

### Changed (BREAKING)
- **오케스트레이터 제거 → 파일 기반 핸드오프** — Anthropic 원문 아키텍처와 동일하게 변경
  - 중앙 오케스트레이터(Agent subprocess dispatch) 제거
  - 하나의 연속 세션에서 역할 루프로 진행
  - 각 역할이 state.md의 `next_role`을 읽고 → 작업 → 다음 역할 기록
  - "one agent writes a file, another reads it"
- **Generator가 직접 계약 제안** — 별도 Contract Agent 제거, Generator가 계약 작성 후 Evaluator가 검증
- **Evaluator가 판단 로직 소유** — RETRY/PIVOT/ESCALATE 판단 + state.md 업데이트 + sprint-log 기록을 Evaluator 내부로 이동
- **Self-Reset 제거** — 연속 세션 + 자동 compaction 사용
- harness-contract 스킬이 참조 문서로 변경 (별도 에이전트가 아님)

### Added
- **레퍼런스 시스템** — `--ref <url-or-image>` 옵션으로 참조 사이트/이미지 제공
  - URL: agent-browser로 스크린샷 캡처 → docs/harness/references/
  - 이미지: 복사 → docs/harness/references/
  - Generator가 레퍼런스를 참고해서 구현
  - Evaluator가 레퍼런스와 비교 평가
- **스크린샷 시각 분석** — Evaluator가 agent-browser screenshot 후 Read 도구로 이미지를 열어 시각적 분석
- **하드 임계값 스코어링** — "if any one criterion fell below it, the sprint failed"
- **Few-shot 평가 캘리브레이션** — 점수 9/6/3 예시 추가
- 평가 기준에 Anthropic 원문 직접 인용 추가

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
