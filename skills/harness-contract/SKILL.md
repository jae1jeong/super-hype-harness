---
name: harness-contract
description: Contract negotiation between Generator and Evaluator. Generator proposes, Evaluator reviews, iterate until agreed.
allowed-tools: [Read, Write, Glob, Grep]
---

> "The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal to make sure the generator was building the right thing. The two iterated until they agreed." — Anthropic
> Example: "Sprint 3 alone had 27 criteria covering the level editor."

# Contract Negotiation

The Generator and Evaluator agree on what "done" looks like before any code is written. This happens via file-based back-and-forth.

## Process

### Step 1: Generator Proposes

Read the plan from `docs/harness/plans/`. Write a contract proposal to `docs/harness/contract.md`:

```markdown
# Contract: [Project Name]

## What Will Be Built
[high-level summary of the full app]

## Completion Criteria

### 1. [Criterion Name]
- **Test**: [exact command or action to verify]
- **Expected**: [exact expected output or behavior]
- **Type**: build | test | api | browser | cli

### 2. [Criterion Name]
...
(aim for 15-30 criteria for a full app)

## Reference Alignment (if references exist)
- [which reference patterns will be matched]

## Verification Commands
\`\`\`bash
[commands to verify]
\`\`\`
```

### Step 2: Evaluator Reviews

Switch to Evaluator perspective. Read the proposed contract and check:
- Are criteria specific enough? Machine-verifiable?
- Are edge cases covered? (empty states, errors, invalid input)
- For web apps: are browser verification steps included?
- Are there enough criteria? (15-30 for a full app)
- Do criteria cover ALL features in the plan?

Write review comments directly in the contract file under a `## Review` section.

### Step 3: Iterate

Generator reads the review, revises the contract. Evaluator reviews again. Repeat until the `## Review` section says "AGREED".

### Step 4: Handoff

When agreed, update `docs/harness/state.md`:
- `next_role: generator`

## Guidelines

- Every criterion must have a hard threshold — pass or fail, no "mostly works"
- "Each criterion had a hard threshold, and if any one fell below it, the sprint failed"
- Include both positive tests (it works) and negative tests (handles errors)
- For web apps: include browser verification (navigate, click, verify state)
- Criteria should cover: functionality, data persistence, error handling, UI state

<HARD-GATE>
## Evidence Requirement (웹앱 필수)

모든 browser type 기준에는 반드시 **"실제 사용 증거"**가 정의되어야 합니다. "코드에 구현 확인"은 증거가 아닙니다.

올바른 기준 예시:
```
### 11. 미디어 임포트
- **Test**: 브라우저에서 파일을 드래그앤드롭하고 타임라인에 나타나는지 확인
- **Evidence**: 스크린샷 (드롭 전 + 드롭 후)
- **Type**: browser
```

잘못된 기준 예시 (금지):
```
### 11. 미디어 임포트
- **Test**: 코드에 import 로직이 구현되어 있는지 확인
- **Type**: build
```

Evaluator는 "Evidence" 필드에 명시된 증거(스크린샷, 커맨드 출력)가 없으면 해당 기준을 PASS로 판정할 수 없습니다.
</HARD-GATE>

<HARD-GATE>
## Anti-Stub Criteria (필수)

Contract에 반드시 다음 기준을 포함해야 합니다:
1. **End-to-end 데이터 플로우**: 생성 → 저장 → 새로고침 → 여전히 존재
2. **핵심 기능 실제 동작**: setTimeout이나 console.log로 시뮬레이션하는 기능 = FAIL
3. **에러 처리**: 잘못된 입력 시 적절한 에러 메시지 표시
</HARD-GATE>
