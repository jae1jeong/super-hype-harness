# Super Hype Harness

Long-running app development harness for Claude Code. Orchestrates a
Planner → Generator → Evaluator pipeline with automatic context reset,
skill ecosystem integration (gstack/superpowers), and rate limit auto-resume.

Inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps).

## Install

```bash
claude plugins install github:jaewon/super-hype-harness
```

## Usage

```bash
/harness "daily briefing app for my Google Calendar"
/harness-status
/harness --resume
```

## Requirements

- Claude Code (latest)

### Optional (enhanced features)

- [gstack](https://github.com/garrytan/gstack) -- plan-ceo-review, plan-eng-review, review, ship
- [superpowers](https://github.com/obra/superpowers) -- brainstorming patterns
- [agent-browser](https://github.com/vercel-labs/agent-browser) -- browser QA

## How It Works

1. **Brainstorm** -- Interactive Q&A to flesh out your app idea (office-hours style)
2. **Review** -- CEO review (scope/ambition) + Eng review (architecture/security)
3. **Plan** -- Decompose spec into sprints with testable contracts
4. **Build** -- Generator implements, Evaluator verifies (GAN-inspired loop)
5. **QA** -- Full app verification (browser for web, tests for CLI/library)
6. **Ship** -- PR creation and deployment

Each phase runs in an isolated Agent subprocess (context reset).
Rate limit auto-resume keeps the pipeline running across sessions.

## Extending

Add custom generators in `generators/` and evaluators in `evaluators/`.
See `generators/README.md` and `evaluators/README.md` for details.
