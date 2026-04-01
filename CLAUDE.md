# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Hype Harness is a **Claude Code plugin** for long-running app development. Agent subprocess per phase (context reset) + Build/QA rounds + config-based skill whitelist.

Version 0.8.0. Skill-only project — no build step, no test suite. All logic in SKILL.md files.

## Architecture — V3 (Agent subprocess + Build/QA rounds)

- **Agent subprocess per phase** — each phase runs in isolated context (fresh start). Orchestrator dispatches and reads file outputs only.
- **Build/QA rounds** — Generator builds entire app, Evaluator tests in single pass. FAIL -> fix -> re-test. No sprints.
- **Skill whitelist** — config.skills controls which skills sub-agents can use. External skill chaining blocked.
- **Contract negotiation** — Generator proposes, Evaluator reviews, iterate until agreed.
- **Screenshot-and-study** — Evaluator takes screenshots, reads them with Read tool for visual analysis.

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
