---
name: harness-remove-config
description: 하네스 config.md를 삭제하여 다음 /harness 실행 시 최신 템플릿으로 재생성되게 합니다.
allowed-tools: [Read, Bash, Glob]
---

# Remove Config

기존 `docs/harness/config.md`를 삭제합니다. 다음 `/harness` 실행 시 최신 SKILL.md 템플릿 기준으로 config가 재생성됩니다.

하네스 템플릿이 업데이트됐는데 기존 config가 구버전일 때 사용합니다.

## Process

1. `docs/harness/config.md` 존재 확인. 없으면: "config.md가 존재하지 않습니다." 후 종료.
2. 현재 config 내용을 읽어서 사용자에게 표시:
   ```
   현재 config:
     generator_skills: [목록]
     evaluator_skills: [목록]
     skills: [목록]
     max_rounds: N
   ```
3. `docs/harness/config.md` 삭제.
4. 완료 메시지:
   ```
   config.md 삭제 완료.
   다음 /harness 실행 시 최신 기본값으로 재생성됩니다.
   커스텀 스킬 설정이 있었다면 재생성 후 다시 설정하세요.
   ```
