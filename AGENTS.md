# Super Hype Harness — Codex Instructions

> This file enables Codex CLI compatibility. For Claude Code, use `/harness` directly.

## Architecture

File-based handoff between agents. No central orchestrator. Each agent reads `docs/harness/state.md` to know its role, does work, writes output files, and updates `next_role`.

## Skills

Skills in `skills/` directory. Codex users: symlink to `.agents/skills/`.

```bash
ln -s ./skills .agents/skills
```

## Available Commands

- `/harness "app description"` — Run the full pipeline
- `/harness "app" --ref https://example.com` — With reference site
- `/harness --resume` — Resume a paused pipeline
- `/harness-status` — Show pipeline progress

## How It Works

1. **Bootstrap** — Create dirs, config, state.md
2. **Brainstorm** — Interactive Q&A → spec document
3. **Review** — Scope + engineering + design review
4. **Plan** — Spec → sprints with testable criteria
5. **Build** — Generator proposes contract, implements, self-evaluates, writes handoff
6. **Evaluate** — Evaluator opens app, screenshots, studies, tests, writes feedback + judgment
7. **QA** — Full app verification
8. **Ship** — Tests + PR creation

Communication via files in `docs/harness/`. State transitions via `state.md`.
