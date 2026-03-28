# Super Hype Harness — Codex Instructions

> For Claude Code, use `/harness` directly.

## Architecture

File-based handoff. No orchestrator, no sprints. One continuous session.

Planner → Contract Negotiation → Generator builds everything → Evaluator tests entire app → fix and re-test rounds until PASS → Ship.

## Skills

```bash
ln -s ./skills .agents/skills
```

## Commands

- `/harness "app description"` — Full pipeline
- `/harness "app" --ref https://example.com` — With reference
- `/harness --resume` — Resume
- `/harness-status` — Progress
