---
name: harness-retro
description: 하네스로 만든 프로젝트의 회고. 앱 실행 검증 + 원문 Anthropic 글 원칙 대비 파이프라인 충실도 분석.
argument-hint: [project-dir] [--run-app] [--deep]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch, Agent]
---

> "Every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing." — Anthropic

# Harness Retro (회고)

하네스 파이프라인으로 만든 프로젝트를 두 축으로 회고합니다:

1. **실행 검증** — 프로젝트가 의도대로 동작하는가?
2. **원칙 충실도** — Anthropic 원문 글의 핵심 원칙이 파이프라인에서 잘 구현되었는가?

## Arguments

Parse `$ARGUMENTS` for:
- `[project-dir]` — 대상 프로젝트 경로 (기본: 현재 디렉토리)
- `--run-app` — 앱을 실제로 실행하고 브라우저로 검증
- `--deep` — 소스코드까지 깊게 분석

---

## Phase 1: 프로젝트 상태 수집

### 1.1 하네스 산출물 읽기

```
docs/harness/state.md        → 파이프라인 상태
docs/harness/config.md       → 설정
docs/harness/contract.md     → 계약서
docs/harness/specs/           → 스펙
docs/harness/plans/           → 플랜
docs/harness/build-log.md    → 빌드 로그
docs/harness/pipeline-log.md → 파이프라인 로그
docs/harness/feedback/        → QA 피드백 전체
docs/harness/handoff/         → 핸드오프 문서 전체
README.md                     → 리드미
```

모든 파일을 읽고 전체 파이프라인 이력을 재구성하라.

### 1.2 Git 이력 분석

```bash
git log --oneline --all
git log --format="%h %s" --since="$(head -1 docs/harness/pipeline-log.md 2>/dev/null | grep -oP '\d{4}-\d{2}-\d{2}' || echo '1970-01-01')"
```

커밋 메시지에서 각 라운드의 빌드/QA 사이클을 추적하라.

### 1.3 앱 실행 검증 (--run-app 또는 app_type: web)

웹앱인 경우:
1. `npm run build` (또는 해당 빌드 커맨드) — 빌드 성공 여부
2. `npm run start` 또는 `npm run dev` — 실행 후 브라우저로 접속
3. Playwright MCP로 메인 페이지 스크린샷 + 스냅샷
4. 계약서(contract.md)의 핵심 기준 3~5개를 빠르게 스팟체크
5. 콘솔 에러 확인

CLI/Library인 경우:
1. 빌드 커맨드 실행
2. 기본 실행/테스트 커맨드 실행
3. 핵심 기능 스팟체크

---

## Phase 2: Anthropic 원문 원칙 대비 분석

원문: [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)

아래 **8가지 핵심 원칙**에 대해 각각 이 프로젝트의 파이프라인이 얼마나 충실했는지 평가하라.

### P1. Generator-Evaluator 분리

> "Separating the agent doing the work from the agent judging it proves to be a strong lever."
> "Tuning a standalone evaluator to be skeptical turns out to be far more tractable than making a generator critical of its own work."

**체크리스트:**
- [ ] Generator와 Evaluator가 실제로 분리된 역할로 실행되었는가?
- [ ] Evaluator가 소스 코드를 수정하지 않았는가? (docs/harness/ 파일만 수정)
- [ ] Evaluator가 실제로 앱을 실행하고 테스트했는가? (스크린샷 증거)
- [ ] Generator의 자체 평가와 Evaluator의 평가가 다른 점이 있었는가? (회의적 평가)

**증거 수집:** pipeline-log.md에서 generator/evaluator 교대 패턴, feedback/ 파일에서 FAIL 판정 내역

### P2. Evaluator 회의주의 (Skepticism)

> "Out of the box, Claude is a poor QA agent... would identify legitimate issues, then talk itself into deciding they weren't a big deal."

**체크리스트:**
- [ ] Evaluator가 최소 1회 이상 FAIL 판정을 내렸는가?
- [ ] FAIL 사유가 구체적이고 재현 가능했는가? (steps to reproduce)
- [ ] "대체로 잘 됨" 식의 관대한 평가가 없었는가?
- [ ] 점수가 라운드별로 실제로 개선되었는가? (improving trend)

**증거 수집:** feedback/ 파일들의 점수 추이, FAIL 사유의 구체성

### P3. 계약 협상 (Contract Negotiation)

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal."

**체크리스트:**
- [ ] contract.md가 존재하고 AGREED 상태인가?
- [ ] 각 기준이 machine-verifiable한가? (스크린샷, 명령어 출력 등)
- [ ] Anti-Stub 검증이 포함되어 있는가?
- [ ] Edge case 검증이 포함되어 있는가?
- [ ] 기준 수가 스펙 대비 충분한 커버리지인가?

**증거 수집:** contract.md의 기준 수와 커버리지 매핑

### P4. 파일 기반 핸드오프 (File-Based Handoff)

> "Communication was handled via files: one agent would write a file, another agent would read it."

**체크리스트:**
- [ ] 각 라운드마다 handoff/round-N-gen.md가 작성되었는가?
- [ ] 핸드오프에 빌드 증거 (커밋 SHA, 빌드 성공 여부)가 포함되었는가?
- [ ] Evaluator가 핸드오프를 읽고 반응한 흔적이 있는가?
- [ ] state.md가 올바르게 업데이트되며 next_role 전환이 이루어졌는가?

**증거 수집:** handoff/ 파일 존재 여부, state.md 변경 이력

### P5. 스프린트 제거 (V2 아키텍처)

> "I started by removing the sprint construct entirely."
> "The model handled 2+ hours of coherent building without sprint decomposition."

**체크리스트:**
- [ ] Generator가 스프린트 없이 전체 앱을 한 패스로 빌드했는가?
- [ ] QA가 빌드 라운드 끝에 단일 패스로 실행되었는가? (스프린트별 QA 아님)
- [ ] Build → QA → Fix → Re-QA 사이클이 올바르게 반복되었는가?

**증거 수집:** build-log.md의 라운드 구조

### P6. 스크린샷 기반 평가 (Screenshot-and-Study)

> "The evaluator would navigate the page on its own, screenshotting and carefully studying the implementation."

**체크리스트:**
- [ ] Evaluator가 실제 브라우저로 앱에 접근했는가?
- [ ] 스크린샷이 feedback/ 또는 .playwright-mcp/에 저장되었는가?
- [ ] 스크린샷을 Read tool로 읽어 시각적으로 분석했는가?
- [ ] 여러 페이지/경로를 탐색했는가? (Free Exploration)

**증거 수집:** 스크린샷 파일 존재, feedback에서 "스크린샷" 언급

### P7. 단순성 원칙 (Simplicity)

> "Find the simplest solution possible, and only increase complexity when needed."
> "Every component in a harness encodes an assumption about what the model can't do on its own."

**체크리스트:**
- [ ] 불필요한 복잡성이 추가되지 않았는가? (과도한 라운드, 불필요한 역할)
- [ ] 파이프라인 단계가 각각 실질적 가치를 제공했는가?
- [ ] Planner가 범위를 적절히 잡았는가? (under-scope 또는 over-scope 없이)

**증거 수집:** pipeline-log.md의 단계별 소요 시간, 각 단계의 실질 기여

### P8. 비용-품질 트레이드오프

> 20x cost increase justified by 20x output quality improvement.

**체크리스트:**
- [ ] 전체 파이프라인 소요 시간과 라운드 수가 기록되어 있는가?
- [ ] QA 점수가 라운드별로 실제 개선되었는가?
- [ ] 최종 결과물이 solo agent 대비 의미 있는 품질 향상을 보이는가?
- [ ] 불필요한 라운드 (점수 변화 없는 반복)가 없었는가?

**증거 수집:** build-log.md의 점수 추이, 총 소요 시간

### P9. 테스트 케이스 중복 검사 (Test Case Deduplication)

> Phase 5.3 Comprehensive Testing에서 여러 Teammate가 동일/유사한 테스트를 반복 실행하면 토큰과 시간이 낭비된다.

**체크리스트:**
- [ ] test-cases.md에서 동일/유사한 케이스가 서로 다른 Teammate에게 중복 할당되지 않았는가?
- [ ] Teammate 간 테스트 범위가 명확히 분리되어 있는가? (Component vs E2E vs Edge)
- [ ] Adversarial Reviewer가 중복 테스트를 식별하고 지적했는가?
- [ ] 중복 테스트 비율이 전체 케이스의 20% 이하인가?

**분석 방법:**
1. `docs/harness/feedback/round-N-*.md` 전체를 읽고 각 Teammate가 실행한 테스트 케이스를 추출
2. 테스트 케이스의 **대상 컴포넌트 + 액션 + 기대 결과**를 비교하여 유사도 판별
3. 중복 유형 분류:
   - **완전 중복**: 동일 컴포넌트, 동일 액션, 동일 기대 결과 (서로 다른 Teammate가 실행)
   - **부분 중복**: 동일 컴포넌트에 대해 유사한 액션을 약간 다른 관점에서 테스트
   - **의도적 교차 검증**: 서로 다른 관점(기능 vs 디자인)에서 같은 영역을 테스트 — 이는 허용
4. 중복 비율 = (완전 중복 + 부분 중복) / 전체 케이스 수

**증거 수집:** feedback/ 파일들의 테스트 케이스 비교, test-cases.md의 카테고리별 분포, 중복 케이스 목록

---

## Phase 3: README 검증

현재 README.md를 읽고 다음을 체크:

- [ ] README가 create-next-app 기본 템플릿 그대로인가? (교체 필요)
- [ ] 프로젝트 목적/설명이 스펙과 일치하는가?
- [ ] 실행 방법 (Getting Started)이 정확한가?
- [ ] 기술 스택이 명시되어 있는가?
- [ ] 스크린샷이나 데모가 포함되어 있는가?

README가 기본 템플릿이면 **자동으로 교체 초안을 생성**하라 (적용은 사용자 확인 후).

---

## Phase 4: 회고 보고서 작성

`docs/harness/retro.md`에 회고 보고서를 작성하라:

```markdown
# 하네스 회고 — [프로젝트명]

> 생성일: [날짜]
> 파이프라인 기간: [시작 ~ 종료]
> 총 라운드: [N]

## 실행 검증 결과

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | PASS/FAIL | [에러 내용] |
| 실행 | PASS/FAIL | [포트, 에러] |
| 핵심 기능 스팟체크 | N/M PASS | [실패 항목] |
| 콘솔 에러 | N개 | [심각도] |

## Anthropic 원칙 충실도

| 원칙 | 점수 | 평가 |
|------|------|------|
| P1. Generator-Evaluator 분리 | ★★★☆☆ | [한줄 평가] |
| P2. Evaluator 회의주의 | ★★★☆☆ | [한줄 평가] |
| P3. 계약 협상 | ★★★☆☆ | [한줄 평가] |
| P4. 파일 기반 핸드오프 | ★★★☆☆ | [한줄 평가] |
| P5. 스프린트 제거 (V2) | ★★★☆☆ | [한줄 평가] |
| P6. 스크린샷 기반 평가 | ★★★☆☆ | [한줄 평가] |
| P7. 단순성 원칙 | ★★★☆☆ | [한줄 평가] |
| P8. 비용-품질 트레이드오프 | ★★★☆☆ | [한줄 평가] |
| P9. 테스트 케이스 중복 검사 | ★★★☆☆ | [한줄 평가] |

### 원칙별 상세 분석

#### P1. Generator-Evaluator 분리
**점수: ★★★☆☆**

[증거 기반 상세 분석. 체크리스트 결과 포함.]

... (P2~P8 반복)

## 잘된 점 (Keep)
1. [구체적 사례와 증거]
2. ...

## 개선할 점 (Improve)
1. [구체적 사례와 개선 방향]
2. ...

## 시도할 점 (Try)
1. [다음 프로젝트에서 실험할 아이디어]
2. ...

## README 상태
- 현재: [기본 템플릿 / 커스텀]
- 권장: [교체 필요 여부 + 초안 경로]

## 하네스 개선 제안
[이 프로젝트 경험을 바탕으로 super-hype-harness 자체의 개선 포인트]
```

## 점수 기준

| 점수 | 의미 |
|------|------|
| ★★★★★ | 원칙을 완벽히 구현. 원문 예시 수준. |
| ★★★★☆ | 원칙을 잘 따름. 사소한 개선 여지. |
| ★★★☆☆ | 기본적으로 따르나 일부 누락 또는 형식적 이행. |
| ★★☆☆☆ | 원칙을 부분적으로만 따름. 실질적 개선 필요. |
| ★☆☆☆☆ | 원칙이 거의 구현되지 않음. |

---

## 완료

회고 보고서 작성 후:
1. Git commit: `docs: 하네스 회고 보고서 작성`
2. 사용자에게 핵심 발견 3가지를 요약 보고
3. README 교체가 필요하면 초안을 제시하고 확인 요청
