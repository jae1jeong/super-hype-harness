---
name: harness-planner
description: Expands a reviewed spec into a full product spec with visual design language. No sprint decomposition — the Generator builds everything at once.
allowed-tools: [Read, Write, Glob, Grep, WebFetch]
---

> "The planner step expanded that prompt into a 16-feature spec spread across ten sprints" "gave the planner access to our frontend design skill, which it read and used to create a visual design language for the app as part of the spec." — Anthropic

# Harness Planner

Expands the reviewed spec into a detailed, implementation-ready product spec. Creates a visual design language. Does NOT decompose into sprints — the Generator builds everything in one pass.

## Input

Read the spec path from `docs/harness/state.md` → `spec` field.
If references exist (`has_references: true`), read `docs/harness/references/index.md` and reference images.

## Process

### 1. Read Frontend Design Skill (web apps)

> "gave the planner access to our frontend design skill"

For web apps, fetch and read the frontend design skill for design guidance:
```
https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md
```

Use its principles to create a visual design language for this app.

### 2. Expand the Spec

Take the brainstorm spec and expand it into a full implementation-ready product spec:

- **Feature list** with detailed descriptions (aim for 10-20 features)
- **Visual design language**: color palette, typography scale, spacing system, component style, mood/identity
- **Data model**: entities, relationships, fields
- **API design**: endpoints, methods, request/response shapes
- **Key screens**: detailed layout descriptions
- **User flows**: step-by-step interaction sequences
- **AI integration points**: if applicable, how the LLM agent drives functionality via tools

### 3. Reference Integration (if references exist)

Study reference images and incorporate:
- Layout patterns to replicate
- Color scheme to match or adapt
- Typography and spacing patterns
- Interaction patterns observed

## Output

Write to `docs/harness/plans/YYYY-MM-DD-plan.md`:

```markdown
# Product Plan: [Project Name]

## Feature List
1. [Feature]: [detailed description]
2. [Feature]: [detailed description]
...

## Visual Design Language
- **Palette**: [primary, secondary, accent, background, text colors]
- **Typography**: [font family, scale: h1/h2/h3/body/caption sizes]
- **Spacing**: [base unit, scale]
- **Component style**: [rounded/sharp, shadow depth, border style]
- **Mood**: [description of the visual identity]

## Data Model
[entities and relationships]

## API Design
[endpoints with methods and shapes]

## Key Screens
[detailed layout for each screen]

## User Flows
[step-by-step sequences]

## AI Integration (if applicable)
[how LLM agent works within the app]
```

Git commit.

## Handoff

Update `docs/harness/state.md`:
- `plan: docs/harness/plans/YYYY-MM-DD-plan.md`
- `next_role: contract`

Announce: "Plan 작성 완료. 계약 협상으로 진행합니다."
