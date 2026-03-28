# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Hype Harness is a **Claude Code plugin** for long-running app development. File-based handoff between Planner, Generator, and Evaluator in one continuous session. No sprints — the Generator builds everything, then the Evaluator tests in a single pass.

Version 0.4.0. Skill-only project — no build step, no test suite. All logic in SKILL.md files.

## Architecture — Anthropic V2

> "I started by removing the sprint construct entirely." "Communication was handled via files."

- **No orchestrator, no sprints**. `/harness` bootstraps, then a role loop reads `state.md` → executes role → updates `next_role`.
- **Build → QA rounds**. Generator builds entire app → Evaluator tests → if FAIL, Generator fixes → Evaluator re-tests (up to max_rounds).
- **Contract negotiation**. Generator proposes what to build, Evaluator reviews, iterate until agreed.
- **Screenshot-and-study**. Evaluator takes screenshots, reads them with Read tool for visual analysis.
- **Planner creates visual design language** using frontend design skill reference.

## Repository Structure

- `skills/` — Pipeline role skills
- `generators/` — Generator presets (default, frontend)
- `evaluators/` — Evaluator presets (default, browser-qa, design-qa)
- `hooks/stop-failure-handler.sh` — Rate-limit auto-resume hook
- `.claude-plugin/` — Plugin manifest

## Development

```bash
claude plugins install /path/to/super-hype-harness
# /reload-plugins, then /harness "test idea"
```

## Version Bumping

Update: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`.

## Language

커밋 메시지와 사용자 대면 텍스트는 한국어로 작성.
