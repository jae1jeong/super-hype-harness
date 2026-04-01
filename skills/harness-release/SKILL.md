---
name: harness-release
description: GitHub 오픈소스 릴리즈 워크플로우. 버전 범프, CHANGELOG 업데이트, Git 태그, GitHub Release 생성을 자동화. /harness-release로 호출.
argument-hint: <patch|minor|major> [--dry-run]
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Harness Release

GitHub 오픈소스 릴리즈를 한 번에 처리하는 스킬.

## Arguments

- `patch` — 0.6.0 → 0.6.1 (버그 수정)
- `minor` — 0.6.0 → 0.7.0 (새 기능)
- `major` — 0.6.0 → 1.0.0 (브레이킹 체인지)
- `--dry-run` — 실제 커밋/푸시 없이 미리보기만

## Process

### Step 1: 현재 상태 확인

```bash
# 현재 버전
grep '"version"' .claude-plugin/plugin.json

# 미커밋 변경사항 확인
git status

# 마지막 태그 이후 커밋
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

미커밋 변경사항이 있으면 먼저 커밋하라고 안내하고 중단.

### Step 2: 새 버전 계산

현재 버전에서 semver 규칙에 따라 새 버전 계산:
- `patch`: X.Y.Z → X.Y.(Z+1)
- `minor`: X.Y.Z → X.(Y+1).0
- `major`: X.Y.Z → (X+1).0.0

### Step 3: CHANGELOG 생성

마지막 태그 이후 커밋을 분류:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

커밋을 카테고리별로 분류:
- `feat:` → ### Added
- `fix:` → ### Fixed
- `refactor:` → ### Changed
- `chore:` → ### Changed
- `docs:` → ### Changed

### Step 3b: 코드 diff 분석 (커밋 메시지만으로 부족할 때)

커밋 메시지가 모호하거나 변경 범위를 정확히 파악해야 할 때, 실제 코드를 분석:

```bash
# 마지막 태그 이후 변경된 파일 목록
git diff $(git describe --tags --abbrev=0)..HEAD --stat

# 변경된 SKILL.md 파일들의 diff 요약
git diff $(git describe --tags --abbrev=0)..HEAD -- skills/ evaluators/ generators/

# 새로 추가된 파일
git diff $(git describe --tags --abbrev=0)..HEAD --diff-filter=A --name-only

# 삭제된 파일
git diff $(git describe --tags --abbrev=0)..HEAD --diff-filter=D --name-only
```

변경된 파일의 실제 코드를 읽고:
- 새로 추가된 기능/섹션 식별
- 삭제/변경된 동작 식별
- config 필드 추가/삭제 식별
- HARD-GATE 추가/변경 식별

이 분석 결과를 CHANGELOG 엔트리에 반영. 커밋 메시지보다 코드 diff가 더 정확함.

### Step 3c: CHANGELOG 작성

CHANGELOG.md 최상단에 새 버전 엔트리 삽입:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- 새 기능 목록 (코드 diff에서 추출)

### Fixed
- 버그 수정 목록

### Changed
- 변경 사항 목록
```

### Step 3d: README 동기화

변경사항이 README에 영향을 주는지 확인:

1. **새 스킬 추가** → Skills Reference 테이블에 추가
2. **config 필드 변경** → Configuration 섹션 업데이트
3. **파이프라인 흐름 변경** → How It Works 다이어그램 업데이트
4. **새 요구사항** → Requirements 섹션 업데이트
5. **새 CLI 옵션** → Usage 섹션 업데이트

README.md와 README.ko.md 양쪽 모두 업데이트.

변경이 필요하면 수정하고 커밋에 포함. 필요 없으면 스킵.

### Step 4: 버전 범프

다음 파일들의 version 필드를 새 버전으로 업데이트:
1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`

### Step 5: 커밋

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json CHANGELOG.md
git commit -m "chore: release v{NEW_VERSION}"
```

### Step 6: 태그

```bash
git tag v{NEW_VERSION}
```

### Step 7: Push

```bash
git push origin main --tags
```

### Step 8: GitHub Release 생성 (선택)

```bash
# CHANGELOG에서 이번 버전 섹션 추출
# gh release create로 릴리즈 생성
gh release create v{NEW_VERSION}   --title "v{NEW_VERSION}"   --notes-file /tmp/release-notes.md
```

릴리즈 노트는 CHANGELOG의 해당 버전 섹션을 사용.

### Step 9: 완료 안내

```
Released v{NEW_VERSION}!

Tag: v{NEW_VERSION}
Commits: N개
PR: https://github.com/owner/repo/releases/tag/v{NEW_VERSION}

사용자 업데이트:
  claude plugins marketplace update {name}
  claude plugins update {name}@{marketplace}
```

## Dry Run

`--dry-run` 플래그가 있으면:
- Step 1-3만 실행 (상태 확인 + CHANGELOG 미리보기)
- 실제 파일 수정, 커밋, 푸시 없음
- "이렇게 릴리즈됩니다" 미리보기 출력

## 주의사항

- main 브랜치에서만 실행
- 미커밋 변경사항이 있으면 중단
- API 키가 포함된 파일이 없는지 확인
- 태그가 이미 존재하면 중단
