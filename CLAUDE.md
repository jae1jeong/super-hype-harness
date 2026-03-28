# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Super Hype Harness is a **Claude Code plugin** for long-running app development using file-based handoff between agents: Brainstorm → Review → Plan → Generator ↔ Evaluator → QA → Ship.

Version 0.4.0. It is a skill-only project — no build step, no test suite, no compiled output. All logic lives in SKILL.md files.

## Architecture — File-Based Handoff

> "Communication was handled via files: one agent would write a file, another agent would read it." — Anthropic

- **No orchestrator**. `/harness` bootstraps (dirs, config, state.md), then enters a role loop.
- **One continuous session**. No Agent subprocesses for phase transitions. Automatic compaction handles context growth.
- **state.md is the coordination mechanism**. Each role reads `next_role`, does its work, updates `next_role` for the next role.
- **Generator proposes contracts**. The Generator writes what it will build and how to verify it. The Evaluator tests against that contract.
- **Evaluator owns judgment logic**. RETRY/PIVOT/ESCALATE decisions, sprint-log recording, and state.md updates all happen in the Evaluator.

## Repository Structure

- `skills/` — Pipeline role skills (harness bootstrapper, brainstorm, planner, generator, evaluator, QA, resume, status, contract reference)
- `generators/` — Generator presets (default, frontend)
- `evaluators/` — Evaluator presets (default, browser-qa, design-qa)
- `hooks/stop-failure-handler.sh` — StopFailure hook for rate-limit auto-resume
- `.claude-plugin/` — Plugin manifest and marketplace listing

## Key Design Decisions

1. **File-based handoff** — agents communicate by writing/reading markdown files in `docs/harness/`
2. **Screenshot-and-study evaluation** — Evaluator takes screenshots with agent-browser, then reads them with the Read tool for visual analysis
3. **Hard thresholds** — each contract criterion is pass/fail, any single failure = sprint fails
4. **Reference system** — `--ref <url-or-image>` provides visual targets for Generator to match
5. **GAN-inspired loop** — Generator builds, Evaluator finds bugs, Generator fixes. Adversarial separation.

## Development Commands

No build or test commands — pure SKILL.md plugin:

```bash
claude plugins install /path/to/super-hype-harness
# In Claude Code: /reload-plugins
# Test: /harness "test app idea"
cat .claude-plugin/plugin.json | jq .version
```

## Version Bumping

Update ALL of these:
1. `.claude-plugin/plugin.json` — `"version"` field
2. `.claude-plugin/marketplace.json` — `"version"` field
3. `CHANGELOG.md` — add new version entry

## Language

커밋 메시지와 사용자 대면 텍스트는 한국어로 작성.
