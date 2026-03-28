---
name: harness-brainstorm
description: harness pipeline brainstorming phase. Fleshes out app ideas into detailed specs using office-hours style interactive Q&A.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch]
---

> Tech decision framework adapted from [dev plugin](https://github.com/anthropics/team-attention-plugins) tech-decision skill.

# Harness Brainstorm

Interactive brainstorming to convert an app idea into a detailed product spec.

## HARD GATE
Do NOT write any code, create any project, or take any implementation action. This skill ONLY produces a spec document. If an external brainstorm skill (e.g., superpowers:brainstorming) tries to chain into implementation skills (writing-plans, executing-plans), STOP and return here.

## Initialization

1. Read `references/question-framework.md` for the 4-phase question structure
2. Check `docs/harness/references/index.md` — if references exist, read and analyze them before starting questions
3. Greet the user and explain the process briefly

## Reference Analysis (if references exist)

Before asking questions, study the reference material:
1. Read each reference image with the Read tool (Claude can see images)
2. Note: layout patterns, color scheme, typography, key interactions, navigation structure
3. Use these observations to inform your questions and spec

## Question Flow

Ask questions ONE AT A TIME. Prefer multiple choice when possible.

Follow the 4-phase framework from `references/question-framework.md`:
1. Vision (What & Why) — understand the core problem
2. Scope — define MVP boundaries
3. Tech Decisions — structured comparison approach
4. UX Flow — map the user journey

### Phase 3: Tech Decisions

Guide the user through tech stack decisions using a structured comparison approach:

1. Based on the app's requirements from Phases 1-2, propose 2-3 tech stack options
2. For each option, present:
   - Stack components (frontend, backend, DB, deployment)
   - Pros for THIS specific project
   - Cons for THIS specific project
   - Effort estimate
3. Make a clear recommendation with reasoning
4. Let the user accept, modify, or override

### Office-Hours Behaviors

- **Push back on framing**: If the user says "I want to build X" but describes something bigger/different, say so.
- **Expand ambitiously**: Suggest capabilities the user didn't mention but their description implies.
- **Challenge premises**: Question assumptions. "Do you really need auth for an MVP?"
- **Respect pullback**: If the user wants to shrink scope, respect it immediately.

### App Type Detection

Based on the conversation, determine app_type:
- **web**: Has UI, runs in browser
- **cli**: Command-line tool
- **library**: Package/module for other code to use

## Output

Write the spec to `docs/harness/specs/YYYY-MM-DD-<name>-spec.md`:

- Project name and one-line description
- Problem statement
- Target user
- Success criteria
- Feature list (MVP vs post-MVP vs excluded)
- Tech stack
- Key screens/views
- User journey
- AI integration points (if any)
- app_type: web | cli | library
- **Reference Analysis** (if references exist): key patterns to replicate, design language, interaction patterns observed

Git commit the spec file.

## Handoff

After writing the spec:
1. Update `docs/harness/config.md` with detected `app_type`
2. Update `docs/harness/state.md`:
   - `spec: docs/harness/specs/YYYY-MM-DD-<name>-spec.md`
   - `next_role: review`
3. Announce: "Spec 작성 완료. state.md에 따라 review 단계로 진행합니다."
