---
name: harness-brainstorm
description: harness pipeline brainstorming phase. Fleshes out app ideas into detailed specs using office-hours style interactive Q&A.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch]
---

> Tech decision framework adapted from [dev plugin](https://github.com/anthropics/team-attention-plugins) tech-decision skill.

# Harness Brainstorm

Interactive brainstorming skill for the harness pipeline. Runs in the main session (NOT as an Agent subprocess) because it requires user conversation.

## Initialization

1. Read `references/question-framework.md` for the 4-phase question structure
2. Greet the user and explain the process briefly

## Process

### HARD GATE
Do NOT write any code, create any project, or take any implementation action. This skill ONLY produces a spec document.

### Question Flow

Ask questions ONE AT A TIME. Prefer multiple choice when possible.

Follow the 4-phase framework from `references/question-framework.md`:
1. Vision (What & Why) -- understand the core problem
2. Scope -- define MVP boundaries
3. Tech Decisions -- structured comparison approach (see below)
4. UX Flow -- map the user journey

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

Example format:
```
Option A: Next.js + Prisma + PostgreSQL + Vercel
  Pros: Full-stack in one framework, great DX, easy deploy
  Cons: Vendor lock-in on Vercel, heavier for simple apps

Option B: Vite + Express + SQLite + manual deploy
  Pros: Lightweight, flexible, no vendor lock-in
  Cons: More manual setup, separate frontend/backend

RECOMMENDATION: Option A because [reason specific to this app].
```

### Office-Hours Behaviors

- **Push back on framing**: If the user says "I want to build X" but describes something bigger/different, say so. "You said daily briefing app, but what you actually described is a personal chief of staff AI."
- **Expand ambitiously**: Suggest capabilities the user didn't mention but their description implies. Let them accept or reject.
- **Challenge premises**: Question assumptions. "Do you really need auth for an MVP?"
- **Respect pullback**: If the user wants to shrink scope, respect it immediately.

### App Type Detection

Based on the conversation, determine app_type:
- **web**: Has UI, runs in browser
- **cli**: Command-line tool
- **library**: Package/module for other code to use

## Output

Write the spec to `docs/harness/specs/YYYY-MM-DD-<name>-spec.md` where:
- YYYY-MM-DD is today's date
- `<name>` is a kebab-case project name derived from the conversation

The spec should include:
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

Git commit the spec file.

## Completion

After writing the spec, announce:
"Spec written to `<path>`. The harness pipeline will now proceed to review and implementation."

Update `docs/harness/config.md` with the detected `app_type`.

After creating all files, commit:
```bash
git add skills/harness-brainstorm/
git commit -m "feat: add harness-brainstorm skill with question framework"
```

IMPORTANT: Actually create the files and commit.
