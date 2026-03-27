# Super Hype Harness — Codex Instructions

> This file enables Codex CLI compatibility. For Claude Code, use `/harness` directly.

## Skills

This project includes harness pipeline skills in `skills/` directory.
Codex users: copy or symlink skills to `.agents/skills/` to use them.

```bash
# Quick setup for Codex
ln -s ./skills .agents/skills
```

## Available Commands

- `/harness "app description"` — Run the full pipeline (brainstorm → review → plan → build → QA → ship)
- `/harness --resume` — Resume a paused pipeline
- `/harness --status` — Show pipeline progress

## How It Works

The harness orchestrates long-running app development through:
1. **Brainstorm** — Interactive Q&A to flesh out your app idea
2. **Review** — Scope review + engineering review (internalized patterns)
3. **Plan** — Decompose spec into sprints with testable contracts
4. **Build** — Generator implements, Evaluator verifies (GAN-inspired loop)
5. **QA** — Full app verification based on app_type (web/cli/library)
6. **Ship** — Test suite + PR creation

Each phase runs in an isolated context to prevent quality degradation on long tasks.
