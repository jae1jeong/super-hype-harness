# Super Hype Harness

**웹 특화** Claude Code용 장기 실행 앱 개발 하네스. 한 줄 명령어로 아이디어부터 PR까지.

Evaluator가 agent-browser와 Playwright로 실제 브라우저에서 스크린샷을 찍고, 네비게이션하고, 앱을 테스트합니다. 웹 애플리케이션 개발에 최적화된 플러그인입니다.

**스프린트 없음. 오케스트레이터 없음.** Planner가 스펙을 만들고, Generator가 전체 앱을 한 번에 빌드하고, Evaluator가 실제 브라우저에서 스크린샷을 찍고 분석하며 전체 앱을 테스트합니다. 실패하면 Generator가 수정하고 다시 테스트. 모든 통신은 파일을 통해 이루어집니다.

> **플랜 참고:** Claude Max $100/월 플랜에서는 보통 ~5라운드 (~2시간) 정도 진행 후 레이트 리밋에 걸립니다. `--rounds` 플래그와 auto-resume가 이를 자연스럽게 처리합니다.

[Anthropic의 Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) 글에서 영감을 받았습니다.

[English](./README.md)

## 설치

```bash
claude plugins marketplace add jae1jeong/super-hype-harness
claude plugins install super-hype-harness@super-hype-harness
```

## 사용법

```bash
# 시작
/harness "구글 캘린더용 일일 브리핑 앱"

# 레퍼런스 사이트와 함께
/harness "캘린더 앱" --ref https://cal.com

# 디자인 목업과 함께
/harness "대시보드" --ref ./mockup.png

# 진행 상황 확인
/harness-status

# 레이트 리밋 후 재개
/harness --resume
```

## 요구사항

- Claude Code (최신 버전)
- `gh` CLI (PR 생성용)
- [agent-browser](https://github.com/vercel-labs/agent-browser) — **웹 앱 필수.** Evaluator가 스크린샷을 찍고 분석합니다.

## 작동 방식

> "I started by removing the sprint construct entirely... find the simplest solution possible, and only increase complexity when needed." — Anthropic

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
 3단계 점진적 QA:
    |
    |  Phase 1 — Functional (동작하는가?):
    |    Generator 빌드 → Evaluator가 모든 기능 테스트
    |    스텁? FAIL. 코드 리뷰만? FAIL. 실제로 앱을 사용해야 함.
    |    스텁 제로, 모든 기능 실제 동작할 때까지 반복.
    |
    |  Phase 2 — Quality (품질이 좋은가?):
    |    새로운 Evaluator → 디자인, 콘솔 에러, 반응형, 접근성
    |    AI 슬롭? FAIL. 콘솔 에러? FAIL. 점수 < 7? FAIL.
    |    품질이 충분할 때까지 반복.
    |
    |  Phase 3 — Edge Cases (견딜 수 있는가?):
    |    새로운 Evaluator → 빈 입력, 더블 클릭, 뒤로가기,
    |    대용량 파일, 경계값, 에러 복구
    |    크래시나 원시 에러? FAIL. 견고할 때까지 반복.
    |
    v
 Ship (테스트 + PR 생성)
```

**핵심 설계 원칙:**
- **페이즈별 Agent subprocess** — 각 페이즈마다 새로운 컨텍스트 (컨텍스트 리셋)
- **파일 기반 핸드오프** — "한 에이전트가 파일을 쓰고, 다른 에이전트가 읽는다"
- **스프린트 없음** — Generator가 전체를 빌드한 후 3단계 점진적 QA
- **3단계 QA** — Functional (동작?) → Quality (품질?) → Edge Cases (견고?)
- **라운드 제한 없음** — 각 페이즈 내에서 PASS할 때까지 반복 (`--rounds`로 제한 가능)
- **계약 협상** — "둘이 합의할 때까지 반복"한 후 코딩 시작
- **스크린샷 분석** — Evaluator가 스크린샷을 Read 도구로 시각 분석
- **하드 임계값** — 스텁 = FAIL, 콘솔 에러 = FAIL, 코드 리뷰 = 증거 아님
- **스킬 화이트리스트** — config.skills로 서브 에이전트 사용 가능 스킬 제어
- **레퍼런스 매칭** — `--ref`로 URL이나 이미지 제공

## 파이프라인 산출물

```
docs/harness/
├── specs/           # Brainstorm 결과 (앱 스펙)
├── plans/           # 확장된 제품 계획 + 디자인 언어
├── contract.md      # 합의된 완료 기준 (Generator + Evaluator)
├── handoff/         # 라운드별 Generator → Evaluator 전달
├── feedback/        # 라운드별 Evaluator 피드백
├── references/      # 레퍼런스 스크린샷/이미지
├── screenshots/     # 라운드별 Evaluator 스크린샷 (round-1/, round-2/...)
├── build-log.md     # 라운드 이력 (페이즈, 점수, 소요시간)
├── pipeline-log.md  # 에이전트 디스패치, 스킬 사용, 오케스트레이터 판단 상세 로그
├── test-cases.md    # QA 테스트 케이스 (매 라운드 갱신)
├── state.md         # 파이프라인 상태 + next_role
└── config.md        # 설정
```

## 스킬 레퍼런스

| 스킬 | 타입 | 설명 |
|------|------|------|
| `/harness` | 사용자 호출 | Bootstrap + 역할 루프 |
| `/harness-status` | 사용자 호출 | 파이프라인 진행 상황 및 빌드 로그 |
| `harness-brainstorm` | 역할 | 대화형 앱 기획 |
| `harness-planner` | 역할 | 스펙 확장 + 비주얼 디자인 언어 |
| `harness-contract` | 역할 | Generator↔Evaluator 계약 협상 |
| `harness-generator` | 역할 | 전체 앱 빌드, 자체 평가, 핸드오프 |
| `harness-evaluator` | 역할 | 스크린샷, 분석, 테스트, 판정 (PASS/FAIL) |
| `harness-qa` | 독립형 | 파이프라인 외 독립 QA |
| `harness-resume` | 내부 | 레이트 리밋 후 재개 |
| `/harness-release` | 사용자 호출 | 버전 범프 + CHANGELOG + 태그 + 푸시 + GitHub Release |
| `/harness-remove-config` | 사용자 호출 | 구버전 config.md 삭제, 다음 실행 시 최신 기본값으로 재생성 |

## 설정

```yaml
auto_resume: true
max_rounds: 10            # 각 QA 페이즈별 최대 라운드 수. 0 = 무제한
generator: default        # generators/<name>/SKILL.md
evaluator: default        # evaluators/<name>/SKILL.md
browser_evaluator: browser-qa
app_type: web             # web | cli | library
has_references: false

skills:
  brainstorm:             # 예: office-hours
  ceo_review:
  eng_review:
  design_review:
  evaluate_qa:
  debug:
  code_review:
  ship:
```

## 크레딧

- **[Anthropic Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — 파일 핸드오프, 연속 세션, 빌드→QA 라운드, 계약 협상, 스크린샷 평가, GAN 영감 루프
- **[gstack](https://github.com/garrytan/gstack)** — 리뷰 워크플로우, Ship 파이프라인, office-hours 브레인스토밍
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion, 체계적 디버깅

모든 패턴 내재화 — **외부 플러그인 불필요.**

## 변경 이력

[CHANGELOG.md](./CHANGELOG.md) 참고.
