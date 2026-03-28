# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Hype Harness is a **Claude Code plugin** (not a traditional app) that orchestrates long-running app development through a multi-phase pipeline: Brainstorm → Review → Plan → Sprint Loop (Generator ↔ Evaluator) → QA → Ship. Version 0.3.1.

Version 0.3.2. It is a skill-only project — there is no build step, no test suite, no compiled output. All logic lives in SKILL.md files that Claude Code interprets at runtime.

## Repository Structure

- `skills/` — Pipeline phase skills (harness orchestrator, brainstorm, planner, contract, generator, evaluator, QA, resume, status)
- `generators/` — Generator presets (default, frontend) that define coding standards for the Generator agent
- `evaluators/` — Evaluator presets (default, browser-qa, design-qa) that define evaluation criteria
- `hooks/stop-failure-handler.sh` — StopFailure hook for rate-limit auto-resume (uses `at` command to schedule `claude -p '/harness --resume'`)
- `.claude-plugin/plugin.json` — Plugin manifest (name, version, hook registration)
- `.claude-plugin/marketplace.json` — Marketplace listing for `claude plugins marketplace add`
- `docs/` — Design specs and implementation plans (not runtime artifacts; runtime artifacts are created in the user's project)

## Key Architecture Decisions

1. **Each pipeline phase runs in an isolated Agent subprocess** (context reset) except brainstorming which runs in the main session for user interaction.
2. **Generator-Evaluator is a GAN-inspired loop**: Generator implements code → Evaluator opens the app and tests like a real user (using agent-browser for web apps) → feedback loop with RETRY/PIVOT/ESCALATE flow.
3. **File-based handoff**: all inter-phase communication goes through markdown files in the user's `docs/harness/` directory (contracts, handoffs, feedback, state).
4. **Skill onboarding**: first run detects installed external skills (gstack, superpowers) and lets the user choose per-category mappings stored in `docs/harness/config.md`.
5. **Self-reset**: orchestrator saves state and spawns a fresh session every N sprints to prevent context bloat.

## Development Commands

No build or test commands — this is a pure SKILL.md plugin. To test changes:

```bash
# Install locally as a plugin (from any project directory)
claude plugins install /path/to/super-hype-harness

# Reload after editing skills
# (in Claude Code) /reload-plugins

# Run the pipeline to test
# (in Claude Code) /harness "test app idea"

# Check current version
cat .claude-plugin/plugin.json | jq .version
```

## Version Bumping

When releasing a new version, update ALL of these:
1. `.claude-plugin/plugin.json` — `"version"` field
2. `CHANGELOG.md` — add new version entry at top
3. Git commit and tag

## HARD-GATE Pattern

Skills use `<HARD-GATE>` blocks to enforce pipeline integrity. These are critical and must not be weakened:
- **EXTERNAL SKILL BOUNDARY** (Phase 1): prevents brainstorm skills from chaining into implementation
- **PIPELINE INTEGRITY CHECK** (Phase 2): verifies no code was generated during brainstorm
- **MANDATORY SPRINT LOOP** (Phase 3): prevents external execution frameworks from bypassing the Generator-Evaluator loop
- **ARTIFACT VERIFICATION** (Sprint Checkpoint): requires contract/handoff/feedback files before advancing

## Writing Skills

Each skill is a standalone `SKILL.md` with YAML frontmatter:
```yaml
---
name: skill-name
description: One-line description
argument-hint: <optional args>
allowed-tools: [Tool1, Tool2, ...]
---
```

Skills reference each other by reading `skills/<name>/SKILL.md`. The orchestrator (`skills/harness/SKILL.md`) dispatches phases via the Agent tool.

## Language

커밋 메시지와 사용자 대면 텍스트는 한국어로 작성.
