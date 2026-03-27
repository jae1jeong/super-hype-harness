# Super Hype Harness

Long-running app development harness for Claude Code. One command takes you from idea to PR: brainstorm, review, plan, build, test, ship. The Generator builds, the Evaluator opens a real browser and tests like a user would. When it fails, the Generator fixes and tries again.

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
# Start a new pipeline
/harness "daily briefing app for my Google Calendar"

# Check progress
/harness-status

# Resume after rate limit or interruption
/harness --resume

# Disable auto-resume for this run
/harness --no-auto-resume "my app idea"
```

## Requirements

- Claude Code (latest)
- `gh` CLI (for PR creation in ship phase)

### Optional

- [agent-browser](https://github.com/vercel-labs/agent-browser) — **Strongly recommended for web apps.** The Evaluator uses it to open your app in a real browser, click through flows, fill forms, and catch bugs every sprint. Without it, web QA falls back to curl/build checks (degraded mode).

## How It Works

```
/harness "my app idea"
    |
    v
 Brainstorm (interactive Q&A with you)
    |
    v
 Review (CEO scope review + Design review + Eng architecture review)
    |
    v
 Plan (decompose into sprints with testable contracts)
    |
    v
 Sprint Loop (repeats for each sprint):
    |
    |   Generator -----> implements code, commits
    |       |
    |   Evaluator -----> opens app in browser, tests like a user
    |       |              clicks buttons, fills forms, checks console
    |       |              finds bugs, reports with screenshots
    |       |
    |   PASS? -----> next sprint
    |   FAIL? -----> Generator fixes based on feedback (max 3 retries)
    |   STUCK? ----> Generator tries different approach (max 2 pivots)
    |   GIVE UP? --> log issue, move to next sprint (escalate)
    |
    v
 QA (full app verification with agent-browser)
    |
    v
 Ship (test suite + PR creation via gh)
```

**Key features:**
- Each phase runs in an isolated Agent subprocess (context reset prevents quality degradation on long tasks)
- The Evaluator is independent and skeptical. It does not trust the Generator's claims. It runs the app and checks.
- For web apps, the Evaluator uses [agent-browser](https://github.com/vercel-labs/agent-browser) every sprint to open pages, click elements, fill forms, check for console errors, and capture screenshots as evidence.
- Rate limit auto-resume: if Claude Code hits a rate limit, the pipeline saves state and automatically resumes when the limit resets.
- Orchestrator self-reset: every 3 sprints (configurable), the orchestrator saves state and starts a fresh session to prevent context bloat.

## Pipeline Output

The pipeline creates structured artifacts in your project:

```
docs/harness/
├── specs/           # Brainstorm result (app spec)
├── plans/           # Sprint plan with testable criteria
├── contracts/       # Per-sprint completion contracts
├── handoff/         # Generator -> Evaluator handoff docs
├── feedback/        # Evaluator feedback with evidence
├── qa-report.md     # Final QA report
├── state.md         # Pipeline state (for resume)
└── config.md        # Configuration
```

## Skills Reference

| Skill | Type | Description |
|-------|------|-------------|
| `/harness` | user-invoked | Main orchestrator. Start, resume, or check status. |
| `/harness-status` | user-invoked | Display pipeline progress and sprint scores. |
| `harness-brainstorm` | model-invoked | Interactive app planning (one question at a time, pushback on framing) |
| `harness-planner` | model-invoked | Spec to sprint decomposition (5-15 sprints) |
| `harness-contract` | model-invoked | Sprint contract with testable completion criteria |
| `harness-generator` | model-invoked | Code implementation with verification-before-completion |
| `harness-evaluator` | model-invoked | **Opens the app, tests like a user, finds bugs.** Read-only. Uses agent-browser for web apps. |
| `harness-qa` | model-invoked | Final full-app QA (browser for web, tests for CLI/library) |
| `harness-resume` | internal | Resume from rate limit, self-reset, or manual pause |

### Built-in Presets

**Generators** (in `generators/`):
| Preset | Description |
|--------|-------------|
| `default` | General-purpose fullstack (TypeScript, async/await, no `any`) |
| `frontend` | Frontend-focused (mobile-first, component design, accessibility) |

**Evaluators** (in `evaluators/`):
| Preset | Description |
|--------|-------------|
| `default` | Code quality, contract compliance, test coverage |
| `browser-qa` | agent-browser based: navigate, click, fill, screenshot, console check |
| `design-qa` | Visual consistency, typography, spacing, responsive, accessibility |

## Configuration

The pipeline creates `docs/harness/config.md` with these defaults:

```yaml
auto_resume: true              # Auto-resume after rate limit (default: on)
generator: default             # Generator profile (generators/<name>/SKILL.md)
evaluator: default             # Evaluator profile (evaluators/<name>/SKILL.md)
browser_evaluator: browser-qa  # Browser QA profile (web apps)
self_reset_interval: 3         # Orchestrator resets context every N sprints
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

- **[Anthropic's Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — Planner/Generator/Evaluator pipeline, context reset via Agent subprocesses, GAN-inspired evaluation loops, sprint contracts
- **[gstack](https://github.com/garrytan/gstack)** — Review workflow patterns (CEO/engineering/design review), ship pipeline, investigate/debugging methodology, office-hours brainstorming style
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion, systematic debugging, checklist-driven workflows, HARD-GATE pattern

All patterns are internalized — **no external plugins required**. This plugin is fully standalone.
