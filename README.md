# Super Hype Harness

Long-running app development harness for Claude Code. Orchestrates a
Planner → Generator → Evaluator pipeline with automatic context reset,
skill ecosystem integration (gstack/superpowers), and rate limit auto-resume.

Inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps).

## Install

```bash
# 1. Add marketplace
claude plugins marketplace add jae1jeong/super-hype-harness

# 2. Install plugin
claude plugins install super-hype-harness@super-hype-harness
```

## Usage

```bash
/harness "daily briefing app for my Google Calendar"
/harness-status
/harness --resume
```

## Requirements

- Claude Code (latest)
- `gh` CLI (for PR creation in ship phase)

### Optional

- [agent-browser](https://github.com/vercel-labs/agent-browser) — Enhanced browser QA for web apps (falls back to build/test verification without it)

## How It Works

1. **Brainstorm** -- Interactive Q&A to flesh out your app idea (office-hours style)
2. **Review** -- CEO review (scope/ambition) + Eng review (architecture/security)
3. **Plan** -- Decompose spec into sprints with testable contracts
4. **Build** -- Generator implements, Evaluator verifies (GAN-inspired loop)
5. **QA** -- Full app verification (browser for web, tests for CLI/library)
6. **Ship** -- PR creation and deployment

Each phase runs in an isolated Agent subprocess (context reset).
Rate limit auto-resume keeps the pipeline running across sessions.

## Skills Reference

| Skill | Type | Description |
|-------|------|-------------|
| `/harness` | user-invoked | Main orchestrator. Start a new pipeline or resume. |
| `/harness-status` | user-invoked | Display pipeline progress. |
| `harness-brainstorm` | model-invoked | Interactive app planning (office-hours style) |
| `harness-planner` | model-invoked | Spec to sprint decomposition |
| `harness-contract` | model-invoked | Sprint contract negotiation |
| `harness-generator` | model-invoked | Code implementation agent |
| `harness-evaluator` | model-invoked | Independent QA (read-only, skeptical) |
| `harness-qa` | model-invoked | Final QA (browser/CLI/library) |
| `harness-resume` | internal | Resume from rate limit or self-reset |

## Configuration

The pipeline creates `docs/harness/config.md` with these defaults:

```yaml
auto_resume: true              # Auto-resume after rate limit (default: on)
generator: default             # Generator profile (generators/<name>/SKILL.md)
evaluator: default             # Evaluator profile (evaluators/<name>/SKILL.md)
browser_evaluator: browser-qa  # Browser QA profile (web apps)
self_reset_interval: 3         # Orchestrator resets every N sprints
max_retries: 3                 # Max retries per sprint before pivot
max_pivots: 2                  # Max pivots per sprint before escalate
app_type: web                  # web | cli | library
```

## Codex CLI Support

This plugin also works with [OpenAI Codex CLI](https://developers.openai.com/codex/cli) via `AGENTS.md`.

```bash
# Symlink skills for Codex
cd your-project
ln -s path/to/super-hype-harness/skills .agents/skills
```

See `AGENTS.md` for details.

## Extending

Add custom generators in `generators/` and evaluators in `evaluators/`.
See `generators/README.md` and `evaluators/README.md` for details.

## Credits & Inspiration

This plugin's patterns are adapted from several excellent projects:

- **[Anthropic's Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — The Planner → Generator → Evaluator pipeline architecture, context reset via Agent subprocesses, GAN-inspired evaluation loops
- **[gstack](https://github.com/garrytan/gstack)** — Review workflow patterns (CEO review, engineering review, design review), ship pipeline, investigate/debugging methodology, office-hours brainstorming style
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion discipline, systematic debugging phases, checklist-driven workflows, HARD-GATE pattern, subagent-driven development

All patterns are internalized — **no external plugins required**. This plugin is fully standalone.
