# Super Hype Harness

Long-running app development harness for Claude Code. One command takes you from idea to PR.

**No sprints. No orchestrator.** The Planner creates the spec, the Generator builds everything in one pass, the Evaluator opens a real browser — screenshots, studies, and tests the entire app. Failed? Generator fixes, Evaluator re-tests. Repeat until done. All communication via files.

Inspired by [Anthropic's Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps).

[한국어](./README.ko.md)

## Install

```bash
claude plugins marketplace add jae1jeong/super-hype-harness
claude plugins install super-hype-harness@super-hype-harness
```

## Usage

```bash
# Start
/harness "daily briefing app for my Google Calendar"

# With reference site
/harness "calendar app" --ref https://cal.com

# With design mockup
/harness "dashboard" --ref ./mockup.png

# Check progress
/harness-status

# Resume after rate limit
/harness --resume
```

## Requirements

- Claude Code (latest)
- `gh` CLI (for PR creation)
- [agent-browser](https://github.com/vercel-labs/agent-browser) — **Required for web apps.** The Evaluator screenshots and studies every page.

## How It Works

> "I started by removing the sprint construct entirely... find the simplest solution possible, and only increase complexity when needed." — Anthropic

```
/harness "my app idea" --ref https://example.com
    |
    v
 Bootstrap (dirs, reference capture, state.md)
    |
    v
 Brainstorm (interactive Q&A → spec)
    |
    v
 Review (CEO + Design + Engineering)
    |
    v
 Planner (expand spec, create visual design language)
    |
    v
 Contract Negotiation (Generator proposes, Evaluator reviews, iterate until agreed)
    |
    v
 Build → QA Rounds:
    |
    |  Round 1:
    |    Generator → builds entire app → handoff
    |    Evaluator → screenshots, studies, tests → feedback (FAIL, 6/10)
    |
    |  Round 2:
    |    Generator → fixes based on feedback → handoff
    |    Evaluator → re-tests → feedback (FAIL, 8/10)
    |
    |  Round 3:
    |    Generator → fixes remaining → handoff
    |    Evaluator → re-tests → feedback (PASS, 9/10)
    |
    v
 Ship (tests + PR)
```

**Key design principles:**
- **One continuous session** with automatic compaction
- **File-based handoff** — "one agent writes a file, another reads it"
- **No sprints** — Generator builds everything, Evaluator tests in a single pass
- **Build → QA rounds** — fail, fix, re-test until pass (typically 2-3 rounds)
- **Contract negotiation** — "the two iterated until they agreed" before any code
- **Screenshot and study** — Evaluator reads screenshots for visual analysis
- **Hard thresholds** — "if any one criterion fell below it, the sprint failed"
- **Reference matching** — `--ref` with URL or image

## Pipeline Output

```
docs/harness/
├── specs/           # Brainstorm result (app spec)
├── plans/           # Expanded product plan with design language
├── contract.md      # Agreed completion criteria (Generator + Evaluator)
├── handoff/         # Generator → Evaluator handoff per round
├── feedback/        # Evaluator feedback per round
├── references/      # Reference screenshots and images
├── build-log.md     # Round history (phase, score, duration)
├── state.md         # Pipeline state + next_role
└── config.md        # Configuration
```

## Skills Reference

| Skill | Type | Description |
|-------|------|-------------|
| `/harness` | user-invoked | Bootstrap + role loop |
| `/harness-status` | user-invoked | Pipeline progress and build log |
| `harness-brainstorm` | role | Interactive app planning |
| `harness-planner` | role | Spec expansion + visual design language |
| `harness-contract` | role | Generator↔Evaluator contract negotiation |
| `harness-generator` | role | Build entire app, self-evaluate, handoff |
| `harness-evaluator` | role | Screenshot, study, test, judge (PASS/FAIL) |
| `harness-qa` | standalone | Standalone QA outside pipeline |
| `harness-resume` | internal | Resume from rate limit |

## Configuration

```yaml
auto_resume: true
generator: default        # generators/<name>/SKILL.md
evaluator: default        # evaluators/<name>/SKILL.md
browser_evaluator: browser-qa
max_rounds: 5             # max build→QA rounds before shipping
app_type: web             # web | cli | library
has_references: false

skills:
  brainstorm:             # e.g., office-hours
  ceo_review:
  eng_review:
  design_review:
  evaluate_qa:
  debug:
  code_review:
  ship:
```

## Credits

- **[Anthropic's Harness Engineering](https://www.anthropic.com/engineering/harness-design-long-running-apps)** — File-based handoff, continuous session, build→QA rounds, contract negotiation, screenshot evaluation, GAN-inspired loop
- **[gstack](https://github.com/garrytan/gstack)** — Review workflows, ship pipeline, office-hours brainstorming
- **[superpowers](https://github.com/obra/superpowers)** — Verification-before-completion, systematic debugging

All patterns internalized — **no external plugins required.**

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).
