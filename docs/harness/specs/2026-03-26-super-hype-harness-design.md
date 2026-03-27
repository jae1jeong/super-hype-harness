# Super Hype Harness - Design Spec

## Overview

Anthropic의 [Harness Design for Long-Running Application Development](https://www.anthropic.com/engineering/harness-design-long-running-apps) 글에서 영감을 받은 Claude Code 플러그인.

**핵심 아이디어:** 장기 실행 앱 개발을 Planner → Generator → Evaluator 파이프라인으로 자동화하되, 기존 skill 생태계(gstack, superpowers)를 오케스트레이션하여 각 단계의 품질을 극대화한다.

**진입점:** `/harness "앱 설명"`

---

## 1. 아키텍처

### 1.1 파이프라인 흐름

```
/harness "daily briefing app for my calendar"
    │
    │ Phase 1: 기획
    ▼
 harness-brainstorm (메인 세션 — 사용자 대화 필요)
    office-hours 스타일 질문 프레임워크
    → 아이디어 푸시백, 범위 확장/축소
    → design doc 생성 (docs/harness/specs/)
    │
    │ Phase 2: 리뷰
    ▼
 plan-ceo-review (gstack)
    → 10-section 리뷰, 범위 도전, 야심 점검
    ▼
 plan-eng-review (gstack)
    → 아키텍처 다이어그램, 데이터 플로우
    → 테스트 매트릭스, 실패 모드, 보안
    │
    │ Phase 3: 구현 (Sprint Loop)
    ▼
 harness-planner → Sprint 분해
    │
    ├─ Sprint N ─────────────────────────┐
    │  harness-contract  (완료 기준 합의) │
    │       ↓                            │
    │  harness-generator (구현 + 커밋)    │
    │       ↓                            │
    │  harness-evaluator (독립 검증)      │
    │       ↓                            │
    │  review (gstack - 코드 리뷰)        │
    │       ↓                            │
    │  점수 판정 → 통과/재시도            │
    └────────────────────────────────────┘
         × N sprints
    │
    │ Phase 4: QA & Ship
    ▼
 harness-qa (agent-browser 기반)
    실제 브라우저로 전체 플로우 검증
    → 버그 발견 시 자동 수정 + 재검증
    ▼
 ship (gstack)
    테스트 실행 → VERSION 범프 → PR 생성
```

### 1.2 Context Reset 전략

글의 핵심 인사이트: 장기 작업에서 모델은 컨텍스트 윈도우가 채워지면서 일관성을 잃는다(context anxiety).

**해결:** 각 단계를 독립 Agent 서브프로세스로 실행. 단, brainstorm은 사용자 대화가 필요하므로 메인 세션에서 직접 실행.

```
오케스트레이터 (메인 세션)
    │
    ├─ [직접] harness-brainstorm  ← 메인 세션 (사용자 대화형)
    ├─ Agent: plan-ceo-review     ← 독립 컨텍스트
    ├─ Agent: plan-eng-review     ← 독립 컨텍스트
    ├─ Agent: harness-planner     ← 독립 컨텍스트
    │
    ├─ Sprint 1:
    │   ├─ Agent: contract        ← 독립 컨텍스트
    │   ├─ Agent: generator       ← 독립 컨텍스트
    │   ├─ Agent: evaluator       ← 독립 컨텍스트
    │   └─ Agent: review          ← 독립 컨텍스트
    │
    └─ ...Sprint N
```

**오케스트레이터 self-reset:** `self_reset_interval`(기본 3) sprint마다 오케스트레이터 자신도 state.md에 상태를 저장하고 새 세션으로 전환. 이를 통해 오케스트레이터의 컨텍스트 비대화를 방지.

**구현 메커니즘:**

```
오케스트레이터 A (Sprint 1-3)
    1. state.md에 현재 상태 직렬화 (status: self_resetting)
    2. Git 커밋 (체크포인트)
    3. Bash로 `claude -p "/harness --resume"` 실행 (백그라운드)
    4. 오케스트레이터 A 정상 종료
       ↓
오케스트레이터 B (새 세션)
    1. state.md 읽기 → status: self_resetting 확인
    2. lock 파일 확인 (docs/harness/.lock)
       - lock 존재 + PID 살아있음 → 충돌, 대기 후 재시도
       - lock 없음 또는 stale → lock 획득 후 진행
    3. Sprint 4부터 이어서 실행
    4. 완료 시 lock 해제
```

**충돌 방지:** `docs/harness/.lock` 파일에 PID + timestamp 기록. 오케스트레이터 시작 시 lock 확인하여 동시 실행 방지.

### 1.3 Handoff 메커니즘

**이중 handoff:** 파일 기반 artifact + Git 커밋 체크포인트.

각 에이전트는 구조화된 마크다운 파일을 출력하고, 다음 에이전트는 해당 파일을 입력으로 받는다. 모든 중요 단계에서 Git 커밋으로 롤백 가능.

**Handoff 디렉토리 구조:**

```
docs/harness/
├── specs/           # brainstorm 결과 스펙
├── plans/           # planner 결과 스프린트 계획
├── contracts/       # sprint별 완료 기준
├── handoff/         # generator → evaluator 전달
├── feedback/        # evaluator 피드백
├── state.md         # 오케스트레이터 상태 (resume용)
└── config.md        # 사용자 설정
```

---

## 2. Skill 오케스트레이션

### 2.1 Skill 출처 매핑

All patterns are internalized — no external plugins required. Patterns adapted from [gstack](https://github.com/garrytan/gstack), [superpowers](https://github.com/obra/superpowers), and [dev plugin](https://github.com/anthropics/team-attention-plugins).

| Phase | Skill | 역할 | 원래 영감 |
|-------|-------|------|----------|
| 기획 | `harness-brainstorm` | office-hours 스타일 질문 + 구조화된 기술 스택 비교 | gstack office-hours, dev tech-decision |
| 리뷰 | 오케스트레이터 내재화 | CEO 리뷰 (범위/야심), 디자인 리뷰 (web), Eng 리뷰 (아키텍처/보안) | gstack plan-ceo/eng/design-review |
| 구현 | `harness-planner` | 스펙 → 스프린트 분해 | — |
| 구현 | `harness-contract` | Done 정의 자동 협상 | Anthropic harness sprint contract |
| 구현 | `harness-generator` | 코드 구현 + verification-before-completion | superpowers verification |
| 구현 | `harness-evaluator` | GAN 영감 독립 검증 (read-only) | Anthropic harness evaluator |
| 디버깅 | 오케스트레이터 내재화 | 4단계 systematic debugging | gstack investigate, superpowers systematic-debugging |
| QA | `harness-qa` | app_type별 QA (browser/cli/library) | — |
| 배포 | 오케스트레이터 내재화 | 테스트 실행 + `gh pr create` | gstack ship |

### 2.2 내재화된 패턴 (외부 종속성 없음)

모든 패턴이 harness 자체 SKILL.md에 내재화되어 독립 동작:

- **verification-before-completion** (from superpowers): Generator가 "구현 완료"를 주장하기 전 반드시 테스트/빌드 증거 확인. Evaluator도 PASS 판정 전 실제 검증 증거 필수.
- **systematic-debugging** (from gstack investigate + superpowers): Evaluator FAIL 정체 시 4단계 디버깅(증상 수집→가설→최소 테스트→수정) 수행.
- **HARD-GATE 패턴** (from superpowers): Phase 간 전이에 hard gate 적용. brainstorm 완료 전 구현 불가, 리뷰 통과 전 sprint 시작 불가.
- **checklist-driven review** (from gstack plan-*-review): CEO/Eng/Design 리뷰를 체크리스트 기반으로 내재화.
- **structured tech comparison** (from dev tech-decision): 기술 스택 결정 시 2-3개 옵션 비교 + 추천.

### 2.3 오케스트레이터 자동 판단

오케스트레이터가 각 phase 결과를 파싱하여 자동으로 결정:

```
plan-ceo-review 결과:
  → "범위 과소" → brainstorm으로 돌아가 확장
  → "범위 과대" → brainstorm으로 돌아가 축소
  → "승인" → plan-eng-review로 진행

plan-eng-review 결과:
  → "기술 스택 변경 필요" → 스펙 수정 후 재리뷰
  → "아키텍처 문제" → brainstorm으로 돌아가 재설계
  → "승인" → Sprint 구현 시작

Sprint evaluator 결과:
  → Contract 항목 전체 PASS → 다음 sprint (점수는 참고용)
  → FAIL 항목 있음 → RETRY (최대 3회)
  → RETRY 3회 초과 → PIVOT (접근법 전환, 최대 2회)
  → PIVOT 2회 초과 → ESCALATE (해당 sprint 이슈 기록 후 다음 sprint로 진행)
  → 추세 판단: 직전 2회 반복에서 FAIL 항목 수 비교
    - 감소 추세 → 점진적 개선 계속
    - 동일/증가 → investigate(gstack) 호출로 root cause 분석

review 결과:
  → auto-fix 적용 → re-evaluate
  → 수동 fix 필요 → generator에 피드백 전달

harness-qa 결과:
  → 버그 발견 → 자동 수정 + 재검증 루프
  → 통과 → ship 실행
```

---

## 3. Skill 세부 설계

### 3.1 `/harness` (메인 진입점, user-invoked)

```yaml
name: harness
description: Long-running app harness 파이프라인 실행
argument-hint: <앱 설명> [--resume] [--no-auto-resume] [--status]
allowed-tools: [Agent, Read, Write, Edit, Bash, Glob, Grep, TaskCreate, TaskUpdate]
```

**역할:** 오케스트레이터. brainstorm만 메인 세션에서 직접 실행(사용자 대화 필요), 나머지는 Agent로 디스패치.

**설정 파일:** `docs/harness/config.md`

```yaml
auto_resume: true              # rate limit 자동 재개 (default: on)
generator: default             # generators/ 하위 skill명
evaluator: default             # evaluators/ 하위 skill명
browser_evaluator: browser-qa  # 웹앱일 때 추가 evaluator
self_reset_interval: 3         # 오케스트레이터 self-reset 주기 (sprint 수)
max_retries: 3                 # sprint당 RETRY 최대 횟수
max_pivots: 2                  # sprint당 PIVOT 최대 횟수
app_type: web                  # web | cli | library (QA 전략 결정)
```

**오케스트레이터 로직:**

```
1. --resume이면 state.md 읽고 해당 단계부터 재개
   (내부적으로 harness-resume 로직 실행. /harness --resume은 harness-resume의 alias)
2. --status이면 harness-status 호출 후 종료
3. 아니면:
   a. harness-brainstorm 메인 세션에서 직접 실행 (사용자 대화) → spec.md
   b. plan-ceo-review Agent 디스패치 → 결과 파싱
   c. plan-design-review Agent 디스패치 (app_type: web일 때만) → 디자인 리뷰
   d. plan-eng-review Agent 디스패치 → 결과 파싱
   e. harness-planner Agent 디스패치 → plan.md
   f. Sprint Loop:
      i.   harness-contract Agent → contract.md
      ii.  harness-generator Agent → handoff.md + Git 커밋
      iii. harness-evaluator Agent → feedback.md
      iv.  review Agent (gstack) → 코드 리뷰
      v.   점수 판정:
           - Contract 전체 PASS → 다음 sprint
           - FAIL 있음 → RETRY (max_retries까지)
           - RETRY 초과 → PIVOT (max_pivots까지)
           - PIVOT 초과 → ESCALATE (이슈 기록 + 다음 sprint)
   g. harness-qa Agent 디스패치 → app_type에 따라:
      - web: agent-browser 브라우저 검증
      - cli: integration test 실행
      - library: test suite 실행
   h. ship Agent (gstack) → PR 생성
4. self_reset_interval마다 state.md 저장 + 새 세션으로 전환
```

### 3.2 `harness-brainstorm` (기획, 메인 세션에서 직접 실행)

```yaml
name: harness-brainstorm
description: harness 파이프라인의 앱 기획 단계. office-hours 스타일로 아이디어를 상세 스펙으로 구체화.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch]
```

**실행 방식:** Agent 서브프로세스가 아닌 메인 세션에서 직접 실행. 사용자와 대화형으로 질문하며 기획을 구체화해야 하므로 독립 Agent로는 불가.

**질문 프레임워크:**

```
Phase 1: 비전 (What & Why)
├── 핵심 문제: 이 앱이 해결하는 문제는?
├── 타겟 사용자: 누가 쓰나?
├── 핵심 가치: 기존 대안 대비 차별점은?
└── 성공 기준: 뭐가 되면 "완성"인가?

Phase 2: 기능 범위 (Scope)
├── 핵심 기능: 반드시 있어야 하는 것 (MVP)
├── 부가 기능: 있으면 좋은 것
├── 제외 사항: 명시적으로 안 만들 것
└── AI 통합: Claude/LLM을 어디에 쓸지

Phase 3: 기술 결정 (How)
├── 프론트엔드: React/Vue/Svelte 등
├── 백엔드: Express/FastAPI/Next.js 등
├── DB: SQLite/PostgreSQL/없음
├── 배포: Vercel/로컬/기타
└── 외부 API: 필요한 서드파티 서비스

Phase 4: UX 흐름 (Flow)
├── 주요 화면: 몇 개의 핵심 페이지/뷰
├── 사용자 여정: 처음 접속 → 핵심 가치 도달까지
├── 인증: 로그인 필요 여부
└── 반응형: 모바일 대응 필요 여부
```

**핵심 행동:**
- 한 번에 하나씩 질문 (객관식 우선)
- 사용자 답변에 푸시백: "당신이 말한 건 X가 아니라 Y다" (office-hours 패턴)
- 야심찬 범위로 확장하되, 사용자가 축소하면 존중
- 최종 출력: `docs/harness/specs/YYYY-MM-DD-<name>-spec.md`
- Git 커밋

### 3.3 `harness-planner` (스프린트 분해, model-invoked)

```yaml
name: harness-planner
description: 리뷰 완료된 스펙을 실행 가능한 스프린트로 분해
allowed-tools: [Read, Write, Glob, Grep]
```

**입력:** `docs/harness/specs/YYYY-MM-DD-*-spec.md` (CEO/Eng 리뷰 반영 완료)
**출력:** `docs/harness/plans/YYYY-MM-DD-plan.md`

**plan.md 구조:**

```markdown
# Sprint Plan: [프로젝트명]

## 전체 개요
- 총 스프린트: N개
- 예상 기술 스택: [...]
- 의존성 그래프: [...]

## Sprint 1: 프로젝트 초기 셋업
### 목표
프로젝트 스캐폴딩, 개발 환경, 기본 라우팅

### Done 정의
- [ ] `npm run dev` 실행 시 localhost에서 빈 페이지 렌더링
- [ ] 기본 라우팅 동작 확인
- [ ] DB 연결 확인 (해당 시)

### 검증 방법
- 빌드 성공 (exit code 0)
- 개발 서버 응답 확인

## Sprint 2: 핵심 데이터 모델
...
```

### 3.4 `harness-contract` (Sprint Contract 협상, model-invoked)

```yaml
name: harness-contract
description: Generator와 Evaluator 간 sprint contract를 자동 협상
allowed-tools: [Read, Write, Glob, Grep]
```

**입력:** plan.md의 해당 sprint 섹션
**출력:** `docs/harness/contracts/sprint-N.md`

```markdown
# Sprint N Contract

## 완료 기준 (테스트 가능)
1. [구체적, 검증 가능한 기준]
2. [...]

## 검증 방법
- 코드 리뷰: [체크 항목]
- 브라우저 검증: [agent-browser로 확인할 것] (웹앱인 경우)
- 빌드/테스트: [실행할 커맨드]

## 범위 제외
- 이 sprint에서 하지 않을 것
```

### 3.5 `harness-generator` (구현, model-invoked)

```yaml
name: harness-generator
description: sprint contract에 따라 코드를 구현
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
```

**입력:** sprint contract + 이전 evaluator 피드백 (있으면)
**출력:** Git 커밋 + `docs/harness/handoff/sprint-N-gen.md`

**verification-before-completion 적용:**
- "구현 완료" 주장 전 반드시:
  - 빌드 성공 확인 (exit code 0)
  - 테스트 통과 확인 (있으면)
  - contract 항목별 자기 체크

**handoff 구조:**

```markdown
# Generator Handoff - Sprint N

## 구현 내용
- [변경 사항 요약]

## Contract 자기 평가
- [DONE] 항목 1: [증거]
- [DONE] 항목 2: [증거]
- [PARTIAL] 항목 3: [이유]

## 커밋
- [SHA]: [메시지]

## 알려진 이슈
- [있으면]
```

**확장:** `generators/` 디렉토리의 사용자 정의 Generator skill을 읽어서 프롬프트에 주입.

### 3.6 `harness-evaluator` (독립 검증, model-invoked)

```yaml
name: harness-evaluator
description: Generator 결과를 독립적으로 검증. 회의적 기조.
allowed-tools: [Read, Bash, Glob, Grep]
```

**주의:** Evaluator는 Write/Edit 권한 없음. 코드를 수정하지 않고 검증만 수행. 수정은 Generator가 피드백을 받아서 처리.

**입력:** sprint contract + Generator handoff
**출력:** `docs/harness/feedback/sprint-N-eval.md`

**GAN 영감 평가 프로세스:**
1. Generator의 자기 평가를 **불신**하고 독립 검증
2. Contract 항목별 PASS/FAIL 판정
3. 코드 리뷰 (기본 evaluator)
4. 웹앱이면 agent-browser로 실제 사용 검증 (browser-qa evaluator)

**verification-before-completion 적용:**
- PASS 판정 전 반드시 실제 검증 증거 필요
- "잘 될 것 같다"는 PASS가 아님

**판정 규칙:**
- **PASS**: Contract 항목 전체 PASS. 점수(X/10)는 참고용 품질 지표.
- **RETRY**: 1개 이상 FAIL 항목 존재. 구체적 피드백과 함께 Generator에 반환.
- **PIVOT**: RETRY가 max_retries(기본 3)회 초과 시. 현재 접근법으로는 해결 불가, 새 방향 제시.
- **ESCALATE**: PIVOT이 max_pivots(기본 2)회 초과 시. 이슈를 기록하고 다음 sprint로 진행.

**적응 전략:**
- FAIL 항목 수 감소 추세 → 피드백 기반 점진적 개선 계속
- FAIL 항목 수 동일/증가 → investigate(gstack) 호출 → root cause 분석
- PIVOT 시 → 구체적 대안 접근법을 feedback에 명시

**feedback 구조:**

```markdown
# Evaluator Feedback - Sprint N

## 점수: X/10
## 추세: [상승/정체/하락] (이전: Y/10)

## Contract 검증
- [PASS] 항목 1: [증거 - 실행 결과, 스크린샷 등]
- [FAIL] 항목 2: [구체적 실패 내용 + 재현 방법]

## 구체적 이슈
1. [이슈 설명 + 원인 분석]

## 권장 조치
- [구체적 수정 방향]

## 판정
- [ ] PASS → 다음 sprint
- [ ] RETRY → 피드백 반영 후 재시도
- [ ] PIVOT → 접근법 전환 필요
```

### 3.7 `harness-qa` (QA 검증, model-invoked)

```yaml
name: harness-qa
description: 전체 앱 QA. app_type에 따라 검증 전략 분기.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
```

**app_type별 QA 전략:**

| app_type | 검증 방법 | 도구 |
|----------|----------|------|
| web | 브라우저 기반 전체 플로우 검증 | vercel-labs/agent-browser |
| cli | integration test + 실제 CLI 실행 검증 | Bash |
| library | test suite 실행 + API 사용 시나리오 검증 | Bash |

**agent-browser 통합 방식 (app_type: web):**

```
1. 개발 서버 시작
   - Bash로 `npm run dev` (또는 프로젝트에 맞는 명령) 백그라운드 실행
   - localhost:PORT 응답 대기 (최대 30초, health check 폴링)

2. agent-browser 호출
   - Bash로 npx @anthropic-ai/agent-browser 실행
   - 또는 프로젝트에 설치된 경우 직접 import
   - URL: http://localhost:PORT

3. QA 시나리오 실행
   - spec.md의 "사용자 여정"을 기반으로 시나리오 생성
   - 각 시나리오: 네비게이션 → 인터랙션 → 상태 확인
   - 스크린샷 캡처 (증거)

4. 개발 서버 종료
   - PID 기반 정리
```

**공통 프로세스 (모든 app_type):**
1. spec.md 기반 QA 시나리오 생성
2. 시나리오별 검증 실행
3. 버그 발견 시 자동 수정 + 재검증 루프
4. 최종 QA 리포트 생성: `docs/harness/qa-report.md`

### 3.8 `harness-status` (진행 조회, user-invoked)

```yaml
name: harness-status
description: harness 파이프라인의 현재 진행 상황 조회
allowed-tools: [Read, Glob, Grep]
```

**출력 예시:**

```
super-hype-harness: Daily Briefing App
Phase: Implementation (Sprint 3/8)

Sprint 1: PASS  10/10
Sprint 2: PASS   8/10 → 10/10 (2 iterations)
Sprint 3: IN_PROGRESS (Generator running)
Sprint 4-8: PENDING

auto-resume: ON
last-commit: abc1234
```

### 3.9 `harness-resume` (재개 로직)

`/harness --resume`은 내부적으로 이 로직을 실행. 별도 슬래시 커맨드로는 노출하지 않음 (진입점은 `/harness --resume` 하나).

**state.md에서 복원하는 항목:**
- 현재 phase (기획/리뷰/구현/QA/배포)
- 현재 sprint 번호
- 마지막 evaluator 피드백
- 남은 tasks
- Git commit SHA (체크포인트)
- 설정 (config.md)

**재개 시 안전 확인:**
1. Git 상태 확인 — state.md의 last_commit과 현재 HEAD 비교
2. 불일치 시 사용자에게 경고 (수동 변경이 있었을 수 있음)
3. lock 파일 확인 — 다른 오케스트레이터가 실행 중인지 확인

---

## 4. Rate Limit 대응

### 4.1 감지 메커니즘

| 방법 | 시점 | 용도 |
|------|------|------|
| StopFailure 훅 | rate limit 발생 직후 | 상태 저장 + 재개 예약 |
| StatusLine JSON | 실시간 | 사전 경고 (used_percentage > 90%이면 현재 sprint 완료 후 일시정지) |

### 4.2 자동 재개 흐름

```
StopFailure 훅 감지 (error: "rate_limit")
    ↓
stop-failure-handler.sh 실행
    ├── state.md에 현재 상태 직렬화
    ├── resets_at 파싱:
    │     1순위: StatusLine JSON의 rate_limits.five_hour.resets_at
    │     2순위: 파싱 실패 시 기본값 5시간 후
    └── `at` 명령으로 재개 예약:
        claude -p "/harness --resume"
    ↓
새 세션에서 harness-resume 실행
    → state.md 읽기
    → 중단 지점부터 파이프라인 재개
    → 재개 시 여전히 rate limited면:
       exponential backoff (30분 → 1시간 → 2시간) 후 재예약
```

### 4.3 설정

```yaml
# docs/harness/config.md
auto_resume: true   # default: ON, 사용자가 OFF 가능
```

- `--no-auto-resume` 플래그로 일회성 비활성화
- `config.md`에서 `auto_resume: false`로 영구 비활성화

### 4.4 state.md 구조

```yaml
---
status: paused          # running | paused | completed
reason: rate_limit      # rate_limit | self_reset | user_pause
paused_at: 2026-03-26T15:30:00Z
resume_after: 2026-03-26T20:30:00Z
---

## Pipeline State
- project: Daily Briefing App
- spec: docs/harness/specs/2026-03-26-briefing-spec.md
- plan: docs/harness/plans/2026-03-26-plan.md
- current_phase: implementation
- current_sprint: 3
- total_sprints: 8
- last_commit: abc1234
- last_evaluator_feedback: docs/harness/feedback/sprint-2-eval.md
- config: docs/harness/config.md
```

---

## 5. 확장성

### 5.1 사용자 정의 Generator/Evaluator

`generators/`와 `evaluators/` 디렉토리에 SKILL.md를 추가하여 커스터마이징.

**Generator 확장 예시:** `generators/mobile/SKILL.md`

```yaml
---
name: mobile-generator
description: React Native 모바일 앱 특화 Generator
---
# Mobile Generator
## 기술 스택
- React Native + Expo
- ...
## 코딩 규칙
- [프로젝트 특화 규칙]
```

**Evaluator 확장 예시:** `evaluators/api-test/SKILL.md`

```yaml
---
name: api-test-evaluator
description: API 엔드포인트 특화 Evaluator. curl/httpie로 검증.
---
```

**적용:** `docs/harness/config.md`에서 지정:

```yaml
generator: mobile          # generators/mobile/SKILL.md
evaluator: api-test        # evaluators/api-test/SKILL.md
```

### 5.2 gstack/superpowers 의존성

**완전 독립 동작 — 외부 플러그인 불필요:**

| 의존성 | 필수 여부 | 설명 |
|--------|----------|------|
| Claude Code | 필수 | 최신 버전 |
| `gh` CLI | 필수 | Ship phase에서 PR 생성 |
| agent-browser | 선택 | 웹앱 브라우저 QA (없으면 빌드/테스트 검증으로 대체) |

gstack, superpowers, dev 플러그인의 패턴은 모두 내재화됨. fallback 로직 없이 모든 기능이 자체 구현.

---

## 6. 배포 & 설치

### 6.1 디렉토리 구조

```
super-hype-harness/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── harness/
│   │   └── SKILL.md
│   ├── harness-brainstorm/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── question-framework.md
│   ├── harness-planner/
│   │   └── SKILL.md
│   ├── harness-contract/
│   │   └── SKILL.md
│   ├── harness-generator/
│   │   └── SKILL.md
│   ├── harness-evaluator/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── evaluation-criteria.md
│   ├── harness-qa/
│   │   └── SKILL.md
│   ├── harness-status/
│   │   └── SKILL.md
│   └── harness-resume/
│       └── SKILL.md
├── generators/
│   ├── default/
│   │   └── SKILL.md
│   ├── frontend/
│   │   └── SKILL.md
│   └── README.md
├── evaluators/
│   ├── default/
│   │   └── SKILL.md
│   ├── browser-qa/
│   │   └── SKILL.md
│   ├── design-qa/
│   │   └── SKILL.md
│   └── README.md
├── hooks/
│   └── stop-failure-handler.sh
├── LICENSE
└── README.md
```

### 6.2 설치 방법

```bash
# Claude Code 플러그인으로 설치
claude plugins install github:username/super-hype-harness

# 또는 로컬 설치
git clone https://github.com/username/super-hype-harness.git ~/.claude/plugins/marketplaces/super-hype-harness
```

### 6.3 필수 요구사항

- Claude Code (최신 버전)

### 6.4 선택 요구사항 (강화 기능)

- gstack 플러그인 (plan-ceo-review, plan-eng-review, review, ship 사용 시)
- superpowers 플러그인 (brainstorming 패턴 원본 참조 시)
- vercel-labs/agent-browser (브라우저 QA 시)

### 6.5 첫 사용

```bash
# 기본 사용
/harness "daily briefing app for my Google Calendar"

# 진행 상황 확인
/harness-status

# 수동 재개
/harness --resume

# 자동 재개 비활성화
/harness --no-auto-resume "my app description"
```

---

## 7. 설계 원칙 요약

1. **Context reset = Agent 서브프로세스**: 각 단계가 깨끗한 컨텍스트에서 시작
2. **GAN 영감 생성-평가 분리**: Generator와 Evaluator가 독립적으로 동작, 회의적 평가
3. **파일 기반 handoff + Git 체크포인트**: 모든 상태가 파일에 저장, 언제든 롤백 가능
4. **기존 skill 생태계 오케스트레이션**: gstack, superpowers를 재발명하지 않고 조합
5. **graceful degradation**: 의존성 없어도 핵심 기능 동작
6. **SKILL.md 기반 확장**: generators/, evaluators/에 마크다운 추가로 커스터마이징
7. **rate limit 자동 대응**: 상태 저장 + 예약 재개 (default ON, OFF 가능)
8. **오케스트레이터 self-reset**: 장기 실행에서도 컨텍스트 품질 유지
9. **verification-before-completion**: 모든 완료 주장에 증거 필수
10. **brainstorm 이후 완전 자동**: 사용자와 대화형 기획(brainstorm) 후, 구현→QA→배포는 자동 실행
