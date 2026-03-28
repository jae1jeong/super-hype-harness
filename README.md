# Super Hype Harness

Long-running app development harness for Claude Code. One command takes you from idea to PR: brainstorm, review, plan, build, test, ship.

**File-based handoff, one continuous session.** No orchestrator. The Generator builds, the Evaluator opens a real browser — screenshots, studies, and tests like a user would. When it fails, the Generator fixes and tries again. All communication happens via files.

Inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps).

[한국어](./README.ko.md)

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

# With a reference site to match
/harness "calendar app" --ref https://cal.com

# With a design mockup
/harness "dashboard" --ref ./mockup.png

# Check progress
/harness-status

# Resume after rate limit or interruption
/harness --resume
```

## Requirements

- Claude Code (latest)
- `gh` CLI (for PR creation in ship phase)
- [agent-browser](https://github.com/vercel-labs/agent-browser) — **Required for web apps.** The Evaluator uses it every sprint to open your app in a real browser, screenshot pages, study the implementation, and test like a user.

## How It Works

> "Communication was handled via files: one agent would write a file, another agent would read it." — Anthropic

```
/harness "my app idea" --ref https://example.com
    |
    v
 Bootstrap (create dirs, capture references, init state.md)
    |
    v
 Role Loop (one continuous session, file-based handoff):
    |
    ├─ Brainstorm ──→ writes spec ──→ state.md: next_role: review
    |
    ├─ Review ──────→ approves spec ──→ state.md: next_role: planner
    |
    ├─ Planner ─────→ writes plan ──→ state.md: next_role: generator
    |
    ├─ Generator ───→ proposes contract
    |                  implements code
    |                  self-evaluates
    |                  writes handoff ──→ state.md: next_role: evaluator
    |
    ├─ Evaluator ───→ opens app in browser
    |                  screenshots & studies every page
    |                  tests each contract criterion
    |                  compares with reference (if any)
    |                  writes feedback + judgment
    |                  ├─ PASS ──→ next sprint (or QA if last)
    |                  ├─ RETRY ──→ back to generator
    |                  ├─ PIVOT ──→ generator tries new approach
    |                  └─ ESCALATE ──→ log & skip
    |
    ├─ QA ──────────→ full app verification ──→ state.md: next_role: ship
    |
    └─ Ship ────────→ tests + PR creation ──→ done
```

**Key design principles:**
- **One continuous session** with automatic compaction — no context resets between phases
- **File-based handoff** — each role reads files written by the previous role, writes files for the next
- **No orchestrator** — `state.md` is the coordination mechanism, each role updates `next_role`
- **Generator proposes contracts** — "the generator proposed what it would build and how success would be verified"
- **Evaluator screenshots and studies** — not just checking elements exist, but visually analyzing the implementation
- **Hard thresholds** — "if any one criterion fell below it, the sprint failed"
- **Reference matching** — provide a URL or image, the harness tries to replicate it

## Pipeline Output

```
docs/harness/
├── specs/           # Brainstorm result (app spec)
├── plans/           # Sprint plan with testable criteria
├── contracts/       # Per-sprint completion contracts (proposed by Generator)
├── handoff/         # Generator → Evaluator handoff docs
├── feedback/        # Evaluator feedback with screenshots and evidence
├── references/      # Reference screenshots and images
├── qa-report.md     # Final QA report
├── sprint-log.md    # Centralized sprint history (scores, duration, retries)
├── state.md         # Pipeline state + next_role (handoff protocol)
└── config.md        # Configuration
```

## Skills Reference

| Skill | Type | Description |
|-------|------|-------------|
| `/harness` | user-invoked | Bootstrap + role loop. Start, resume, or check status. |
| `/harness-status` | user-invoked | Display pipeline progress and sprint scores. |
| `harness-brainstorm` | role | Interactive app planning (one question at a time) |
| `harness-planner` | role | Spec to sprint decomposition (5-15 sprints) |
| `harness-contract` | reference | Contract format reference (Generator proposes contracts directly) |
| `harness-generator` | role | Propose contract, implement code, self-evaluate, write handoff |
| `harness-evaluator` | role | Screenshot, study, test, judge. Updates state.md with next_role. |
| `harness-qa` | role | Final full-app QA with browser testing |
| `harness-resume` | internal | Resume from rate limit or pause |

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

`docs/harness/config.md` defaults:

```yaml
auto_resume: true
generator: default
evaluator: default
browser_evaluator: browser-qa
max_retries: 3
max_pivots: 2
app_type: web
has_references: false

skills:
  brainstorm:         # e.g., office-hours
  ceo_review:         # e.g., plan-ceo-review
  eng_review:         # e.g., plan-eng-review
  design_review:      # e.g., plan-design-review
  evaluate_qa:        # e.g., browse
  debug:              # e.g., investigate
  code_review:        # e.g., review
  ship:               # e.g., ship
```

## Codex CLI Support

This plugin also works with [OpenAI Codex CLI](https://developers.openai.com/codex/cli) via `AGENTS.md`.

```bash
cd your-project
ln -s path/to/super-hype-harness/skills .agents/skills
```

## Extending

Add custom generators in `generators/` and evaluators in `evaluators/`.
See `generators/README.md` and `evaluators/README.md` for details.

## Credits & Inspiration

- **[Anthropic's Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — File-based handoff, one continuous session, GAN-inspired Generator/Evaluator loop, sprint contracts, screenshot-and-study evaluation
- **[gstack](https://github.com/garrytan/gstack)** — Review workflow patterns, ship pipeline, office-hours brainstorming
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion, systematic debugging, checklist-driven workflows

All patterns are internalized — **no external plugins required**.

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history.
