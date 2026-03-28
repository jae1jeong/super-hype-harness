# Super Hype Harness

Claude Code용 장기 실행 앱 개발 하네스. 한 줄 명령어로 아이디어부터 PR까지.

**스프린트 없음. 오케스트레이터 없음.** Planner가 스펙을 만들고, Generator가 전체 앱을 한 번에 빌드하고, Evaluator가 실제 브라우저에서 스크린샷을 찍고 분석하며 전체 앱을 테스트합니다. 실패하면 Generator가 수정하고 다시 테스트. 모든 통신은 파일을 통해 이루어집니다.

[Anthropic의 Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) 글에서 영감을 받았습니다.

[English](./README.md)

## 설치

```bash
claude plugins marketplace add jae1jeong/super-hype-harness
claude plugins install super-hype-harness@super-hype-harness
```

## 사용법

```bash
/harness "구글 캘린더용 일일 브리핑 앱"
/harness "캘린더 앱" --ref https://cal.com
/harness "대시보드" --ref ./mockup.png
/harness-status
/harness --resume
```

## 요구사항

- Claude Code (최신 버전)
- `gh` CLI (PR 생성용)
- [agent-browser](https://github.com/vercel-labs/agent-browser) — **웹 앱 필수.** Evaluator가 스크린샷을 찍고 분석합니다.

## 작동 방식

> "I started by removing the sprint construct entirely... find the simplest solution possible." — Anthropic

```
/harness "앱 아이디어" --ref https://example.com
    |
    v
 Bootstrap (디렉토리, 레퍼런스 캡처, state.md)
    |
    v
 Brainstorm (대화형 Q&A → spec)
    |
    v
 Review (CEO + Design + Engineering)
    |
    v
 Planner (스펙 확장, 비주얼 디자인 언어 생성)
    |
    v
 계약 협상 (Generator 제안 ↔ Evaluator 리뷰, 합의까지 반복)
    |
    v
 빌드 → QA 라운드:
    |
    |  라운드 1:
    |    Generator → 전체 앱 빌드 → handoff
    |    Evaluator → 스크린샷, 분석, 테스트 → 피드백 (FAIL, 6/10)
    |
    |  라운드 2:
    |    Generator → 피드백 반영 수정 → handoff
    |    Evaluator → 재테스트 → 피드백 (PASS, 9/10)
    |
    v
 Ship (테스트 + PR 생성)
```

**핵심 설계 원칙:**
- **하나의 연속 세션** — 자동 compaction으로 컨텍스트 관리
- **파일 기반 핸드오프** — "한 에이전트가 파일을 쓰고, 다른 에이전트가 읽는다"
- **스프린트 없음** — Generator가 전체를 빌드, Evaluator가 한 번에 테스트
- **빌드→QA 라운드** — 실패하면 수정하고 재테스트 (보통 2-3 라운드)
- **계약 협상** — "둘이 합의할 때까지 반복"한 후 코딩 시작
- **스크린샷 분석** — Evaluator가 스크린샷을 Read 도구로 시각 분석
- **하드 임계값** — "기준 하나라도 미달이면 실패"
- **레퍼런스 매칭** — `--ref`로 URL이나 이미지 제공

## 파이프라인 산출물

```
docs/harness/
├── specs/           # Brainstorm 결과
├── plans/           # 확장된 제품 계획 + 디자인 언어
├── contract.md      # 합의된 완료 기준
├── handoff/         # 라운드별 Generator → Evaluator 전달
├── feedback/        # 라운드별 Evaluator 피드백
├── references/      # 레퍼런스 스크린샷/이미지
├── build-log.md     # 라운드 이력 (점수, 소요시간)
├── state.md         # 파이프라인 상태 + next_role
└── config.md        # 설정
```

## 설정

```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
max_rounds: 5
app_type: web
has_references: false

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

## 크레딧

- **[Anthropic Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — 파일 핸드오프, 연속 세션, 빌드→QA 라운드, 계약 협상, 스크린샷 평가
- **[gstack](https://github.com/garrytan/gstack)** — 리뷰 워크플로우, office-hours 브레인스토밍
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion, 체계적 디버깅

모든 패턴 내재화 — **외부 플러그인 불필요.**

## 변경 이력

[CHANGELOG.md](./CHANGELOG.md) 참고.
