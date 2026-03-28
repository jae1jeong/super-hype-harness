# Super Hype Harness

Claude Code용 장기 실행 앱 개발 하네스. 한 줄 명령어로 아이디어부터 PR까지: 기획, 리뷰, 계획, 구현, 테스트, 배포.

**파일 기반 핸드오프, 하나의 연속 세션.** 오케스트레이터 없음. Generator가 코드를 만들고, Evaluator가 실제 브라우저에서 스크린샷을 찍고 구현을 분석하며 사용자처럼 테스트합니다. 실패하면 Generator가 피드백을 받아 수정합니다. 모든 통신은 파일을 통해 이루어집니다.

[Anthropic의 Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) 글에서 영감을 받았습니다.

[English](./README.md)

## 설치

```bash
# 1. 마켓플레이스 추가
claude plugins marketplace add jae1jeong/super-hype-harness

# 2. 플러그인 설치
claude plugins install super-hype-harness@super-hype-harness
```

## 사용법

```bash
# 새 파이프라인 시작
/harness "구글 캘린더용 일일 브리핑 앱"

# 레퍼런스 사이트를 참고하여 만들기
/harness "캘린더 앱" --ref https://cal.com

# 디자인 목업을 참고하여 만들기
/harness "대시보드" --ref ./mockup.png

# 진행 상황 확인
/harness-status

# rate limit이나 중단 후 재개
/harness --resume
```

## 요구사항

- Claude Code (최신 버전)
- `gh` CLI (Ship 단계에서 PR 생성용)
- [agent-browser](https://github.com/vercel-labs/agent-browser) — **웹 앱 필수.** Evaluator가 매 스프린트마다 실제 브라우저에서 스크린샷을 찍고, 구현을 분석하고, 사용자처럼 테스트합니다.

## 작동 방식

> "Communication was handled via files: one agent would write a file, another agent would read it." — Anthropic

```
/harness "앱 아이디어" --ref https://example.com
    |
    v
 Bootstrap (디렉토리 생성, 레퍼런스 캡처, state.md 초기화)
    |
    v
 역할 루프 (하나의 연속 세션, 파일 기반 핸드오프):
    |
    ├─ Brainstorm ──→ spec 작성 ──→ state.md: next_role: review
    |
    ├─ Review ──────→ spec 승인 ──→ state.md: next_role: planner
    |
    ├─ Planner ─────→ plan 작성 ──→ state.md: next_role: generator
    |
    ├─ Generator ───→ 계약 제안
    |                  코드 구현
    |                  자체 검증
    |                  handoff 작성 ──→ state.md: next_role: evaluator
    |
    ├─ Evaluator ───→ 브라우저에서 앱 열기
    |                  모든 페이지 스크린샷 & 분석
    |                  계약 기준별 테스트
    |                  레퍼런스 비교 (있는 경우)
    |                  피드백 + 판단 작성
    |                  ├─ PASS ──→ 다음 스프린트 (또는 마지막이면 QA)
    |                  ├─ RETRY ──→ Generator로 돌아감
    |                  ├─ PIVOT ──→ Generator가 다른 접근법 시도
    |                  └─ ESCALATE ──→ 기록 & 건너뛰기
    |
    ├─ QA ──────────→ 전체 앱 검증 ──→ state.md: next_role: ship
    |
    └─ Ship ────────→ 테스트 + PR 생성 ──→ 완료
```

**핵심 설계 원칙:**
- **하나의 연속 세션** — 단계 간 컨텍스트 리셋 없음. 자동 compaction으로 컨텍스트 관리
- **파일 기반 핸드오프** — 각 역할이 이전 역할이 쓴 파일을 읽고, 다음 역할을 위한 파일을 작성
- **오케스트레이터 없음** — `state.md`가 조율 메커니즘. 각 역할이 `next_role`을 업데이트
- **Generator가 계약 제안** — "Generator가 무엇을 만들고 어떻게 검증할지 제안"
- **Evaluator가 스크린샷을 찍고 분석** — 요소 존재 확인이 아니라, 실제로 보고 분석
- **하드 임계값** — "어떤 기준 하나라도 미달이면 스프린트 실패"
- **레퍼런스 매칭** — URL이나 이미지를 제공하면 하네스가 그대로 재현 시도

## 파이프라인 산출물

```
docs/harness/
├── specs/           # Brainstorm 결과 (앱 스펙)
├── plans/           # 테스트 가능한 기준이 포함된 스프린트 계획
├── contracts/       # 스프린트별 완료 계약 (Generator가 제안)
├── handoff/         # Generator → Evaluator 전달 문서
├── feedback/        # 스크린샷과 증거가 포함된 Evaluator 피드백
├── references/      # 레퍼런스 스크린샷 및 이미지
├── qa-report.md     # 최종 QA 리포트
├── sprint-log.md    # 스프린트 이력 (점수, 소요시간, 리트라이)
├── state.md         # 파이프라인 상태 + next_role (핸드오프 프로토콜)
└── config.md        # 설정
```

## 스킬 레퍼런스

| 스킬 | 유형 | 설명 |
|------|------|------|
| `/harness` | 사용자 호출 | 부트스트랩 + 역할 루프. 시작, 재개, 상태 확인. |
| `/harness-status` | 사용자 호출 | 파이프라인 진행 상황 및 스프린트 점수 표시. |
| `harness-brainstorm` | 역할 | 대화형 앱 기획 (한 번에 하나씩 질문) |
| `harness-planner` | 역할 | 스펙을 스프린트로 분해 (5-15개) |
| `harness-contract` | 참조 | 계약 포맷 참조 문서 (Generator가 직접 계약 작성) |
| `harness-generator` | 역할 | 계약 제안, 코드 구현, 자체 검증, handoff 작성 |
| `harness-evaluator` | 역할 | 스크린샷, 분석, 테스트, 판단. state.md 업데이트. |
| `harness-qa` | 역할 | 브라우저 테스트로 최종 전체 앱 QA |
| `harness-resume` | 내부 | rate limit 또는 일시정지에서 재개 |

### 내장 프리셋

**Generator** (`generators/`):
| 프리셋 | 설명 |
|--------|------|
| `default` | 범용 풀스택 (TypeScript, async/await, `any` 금지) |
| `frontend` | 프론트엔드 특화 (모바일 퍼스트, 컴포넌트 설계, 접근성) |

**Evaluator** (`evaluators/`):
| 프리셋 | 설명 |
|--------|------|
| `default` | 코드 품질, 계약 준수, 테스트 커버리지 |
| `browser-qa` | agent-browser 기반: 탐색, 클릭, 입력, 스크린샷, 콘솔 체크 |
| `design-qa` | 시각적 일관성, 타이포그래피, 간격, 반응형, 접근성 |

## 설정

`docs/harness/config.md` 기본값:

```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
max_retries: 3
max_pivots: 2
app_type: web
has_references: false

skills:
  brainstorm:         # 예: office-hours
  ceo_review:         # 예: plan-ceo-review
  eng_review:         # 예: plan-eng-review
  design_review:      # 예: plan-design-review
  evaluate_qa:        # 예: browse
  debug:              # 예: investigate
  code_review:        # 예: review
  ship:               # 예: ship
```

## Codex CLI 지원

`AGENTS.md`를 통해 [OpenAI Codex CLI](https://developers.openai.com/codex/cli)에서도 사용 가능.

```bash
cd your-project
ln -s path/to/super-hype-harness/skills .agents/skills
```

## 확장

`generators/`와 `evaluators/`에 커스텀 프리셋을 추가할 수 있습니다.

## 크레딧 & 영감

- **[Anthropic의 Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — 파일 기반 핸드오프, 하나의 연속 세션, GAN 영감 Generator/Evaluator 루프, 스프린트 계약, 스크린샷 분석 평가
- **[gstack](https://github.com/garrytan/gstack)** — 리뷰 워크플로우, Ship 파이프라인, office-hours 브레인스토밍
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion, 체계적 디버깅, 체크리스트 기반 워크플로우

모든 패턴이 내재화되어 있습니다 — **외부 플러그인 불필요.**

## 변경 이력

[CHANGELOG.md](./CHANGELOG.md)에서 버전 히스토리를 확인할 수 있습니다.
