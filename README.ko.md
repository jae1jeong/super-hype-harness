# Super Hype Harness

Claude Code용 장기 실행 앱 개발 하네스. 한 줄 명령어로 아이디어부터 PR까지: 기획, 리뷰, 계획, 구현, 테스트, 배포. Generator가 코드를 만들고, Evaluator가 실제 브라우저에서 사용자처럼 테스트합니다. 실패하면 Generator가 피드백을 받아 다시 수정합니다.

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

# 진행 상황 확인
/harness-status

# rate limit이나 중단 후 재개
/harness --resume

# 이번 실행만 자동 재개 비활성화
/harness --no-auto-resume "앱 아이디어"
```

## 요구사항

- Claude Code (최신 버전)
- `gh` CLI (Ship 단계에서 PR 생성용)

### 선택사항

- [agent-browser](https://github.com/vercel-labs/agent-browser) -- **웹 앱이라면 강력 권장.** Evaluator가 이걸로 실제 브라우저를 열어 페이지를 탐색하고, 폼을 채우고, 버튼을 클릭하며, 매 스프린트마다 버그를 찾습니다. 없으면 curl/빌드 체크로 대체됩니다 (기능 제한).

## 작동 방식

```
/harness "앱 아이디어"
    |
    v
 Brainstorm (사용자와 대화형 Q&A)
    |
    v
 Review (CEO 범위 리뷰 + 디자인 리뷰 + Eng 아키텍처 리뷰)
    |
    v
 Plan (스프린트로 분해, 테스트 가능한 완료 기준 설정)
    |
    v
 Sprint Loop (각 스프린트마다 반복):
    |
    |   Generator -----> 코드 구현, 커밋
    |       |
    |   Evaluator -----> 실제 브라우저에서 앱을 열고 사용자처럼 테스트
    |       |              버튼 클릭, 폼 입력, 콘솔 에러 확인
    |       |              버그 발견, 스크린샷으로 증거 제출
    |       |
    |   통과? -------> 다음 스프린트
    |   실패? -------> Generator가 피드백 반영 후 재시도 (최대 3회)
    |   막힘? -------> Generator가 다른 접근법 시도 (최대 2회 전환)
    |   포기? -------> 이슈 기록 후 다음 스프린트로 (에스컬레이트)
    |
    v
 QA (agent-browser로 전체 앱 검증)
    |
    v
 Ship (테스트 실행 + gh로 PR 생성)
```

**핵심 기능:**
- 각 단계가 독립된 Agent 서브프로세스에서 실행 (context reset으로 장기 작업에서도 품질 유지)
- Evaluator는 독립적이고 회의적. Generator의 주장을 신뢰하지 않고 직접 앱을 실행해서 확인
- 웹 앱의 경우, Evaluator가 매 스프린트마다 [agent-browser](https://github.com/vercel-labs/agent-browser)로 페이지를 열고, 요소를 클릭하고, 폼을 채우고, 콘솔 에러를 확인하고, 스크린샷을 증거로 캡처
- **스킬 온보딩**: 첫 실행 시 설치된 스킬(gstack, superpowers 등)을 감지하고 파이프라인 단계별로 어떤 스킬을 쓸지 선택. 4번의 선택으로 끝.
- Rate limit 자동 재개: Claude Code가 rate limit에 걸리면 파이프라인 상태를 저장하고 리밋 해제 시 자동으로 재개
- 오케스트레이터 self-reset: 3 스프린트마다 (설정 가능) 상태를 저장하고 새 세션으로 전환하여 컨텍스트 비대화 방지

## 파이프라인 산출물

파이프라인이 프로젝트에 생성하는 구조화된 산출물:

```
docs/harness/
+-- specs/           # Brainstorm 결과 (앱 스펙)
+-- plans/           # 테스트 가능한 기준이 포함된 스프린트 계획
+-- contracts/       # 스프린트별 완료 기준 계약
+-- handoff/         # Generator -> Evaluator 전달 문서
+-- feedback/        # 증거가 포함된 Evaluator 피드백
+-- qa-report.md     # 최종 QA 리포트
+-- state.md         # 파이프라인 상태 (재개용)
+-- config.md        # 설정
```

## 스킬 레퍼런스

| 스킬 | 유형 | 설명 |
|------|------|------|
| `/harness` | 사용자 호출 | 메인 오케스트레이터. 시작, 재개, 상태 확인. |
| `/harness-status` | 사용자 호출 | 파이프라인 진행 상황 및 스프린트 점수 표시. |
| `harness-brainstorm` | 모델 호출 | 대화형 앱 기획 (한 번에 하나씩 질문, 프레이밍 푸시백) |
| `harness-planner` | 모델 호출 | 스펙을 스프린트로 분해 (5-15개) |
| `harness-contract` | 모델 호출 | 테스트 가능한 완료 기준으로 스프린트 계약 |
| `harness-generator` | 모델 호출 | verification-before-completion 패턴의 코드 구현 |
| `harness-evaluator` | 모델 호출 | **앱을 열고, 사용자처럼 테스트하고, 버그를 찾는다.** Read-only. 웹 앱은 agent-browser 사용. |
| `harness-qa` | 모델 호출 | 최종 전체 앱 QA (웹은 브라우저, CLI/라이브러리는 테스트) |
| `harness-resume` | 내부 | rate limit, self-reset, 수동 일시정지에서 재개 |

### 내장 프리셋

**Generator** (`generators/` 디렉토리):
| 프리셋 | 설명 |
|--------|------|
| `default` | 범용 풀스택 (TypeScript, async/await, `any` 사용 금지) |
| `frontend` | 프론트엔드 특화 (모바일 퍼스트, 컴포넌트 설계, 접근성) |

**Evaluator** (`evaluators/` 디렉토리):
| 프리셋 | 설명 |
|--------|------|
| `default` | 코드 품질, 계약 준수, 테스트 커버리지 |
| `browser-qa` | agent-browser 기반: 탐색, 클릭, 입력, 스크린샷, 콘솔 체크 |
| `design-qa` | 시각적 일관성, 타이포그래피, 간격, 반응형, 접근성 |

## 설정

파이프라인이 `docs/harness/config.md`를 기본값으로 생성합니다:

```yaml
auto_resume: true              # rate limit 후 자동 재개 (기본: on)
generator: default             # Generator 프로필 (generators/<name>/SKILL.md)
evaluator: default             # Evaluator 프로필 (evaluators/<name>/SKILL.md)
browser_evaluator: browser-qa  # 브라우저 QA 프로필 (웹 앱용)
self_reset_interval: 3         # N 스프린트마다 오케스트레이터 컨텍스트 리셋
max_retries: 3                 # 스프린트당 최대 재시도 횟수 (pivot 전)
max_pivots: 2                  # 스프린트당 최대 접근법 전환 횟수 (escalate 전)
app_type: web                  # web | cli | library

# 스킬 매핑 (온보딩 시 설정, 언제든 수정 가능)
# 비어있으면 내장 패턴 사용. 스킬명 적으면 서브에이전트가 해당 스킬 사용.
skills:
  brainstorm:                  # 예: office-hours
  ceo_review:                  # 예: plan-ceo-review
  eng_review:                  # 예: plan-eng-review
  design_review:               # 예: plan-design-review
  evaluate_qa:                 # 예: browse
  debug:                       # 예: investigate
  code_review:                 # 예: review
  ship:                        # 예: ship
```

## Codex CLI 지원

이 플러그인은 `AGENTS.md`를 통해 [OpenAI Codex CLI](https://developers.openai.com/codex/cli)에서도 사용할 수 있습니다.

```bash
# Codex용 스킬 심링크
cd your-project
ln -s path/to/super-hype-harness/skills .agents/skills
```

자세한 내용은 `AGENTS.md`를 참고하세요.

## 확장

`generators/`와 `evaluators/`에 커스텀 프리셋을 추가할 수 있습니다.
`generators/README.md`와 `evaluators/README.md`를 참고하세요.

## 크레딧 & 영감

이 플러그인의 패턴은 다음 프로젝트들에서 차용했습니다:

- **[Anthropic의 Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** -- Planner/Generator/Evaluator 파이프라인, Agent 서브프로세스를 통한 context reset, GAN 영감 평가 루프, 스프린트 계약
- **[gstack](https://github.com/garrytan/gstack)** -- 리뷰 워크플로우 패턴 (CEO/엔지니어링/디자인 리뷰), Ship 파이프라인, investigate/디버깅 방법론, office-hours 브레인스토밍 스타일
- **[superpowers](https://github.com/obra/superpowers)** -- Verification-before-completion, 체계적 디버깅, 체크리스트 기반 워크플로우, HARD-GATE 패턴

모든 패턴이 내재화되어 있습니다 -- **외부 플러그인이 필요 없습니다.** 이 플러그인은 완전히 독립적으로 동작합니다.

## 변경 이력

[CHANGELOG.md](./CHANGELOG.md)에서 버전 히스토리를 확인할 수 있습니다.
