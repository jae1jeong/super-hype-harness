# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
