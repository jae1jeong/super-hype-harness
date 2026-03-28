# Evaluation Criteria

> Adapted from Anthropic's harness design: "the evaluator would navigate the page on its own, screenshotting and carefully studying the implementation before producing its assessment."

## Evaluation Approach

### Explore First, Judge Second

Before scoring ANY criterion, the evaluator MUST:
1. **Navigate the entire app freely** — not just the pages the contract mentions. Discover what exists.
2. **Screenshot key pages** — capture the actual state before forming opinions.
3. **Study the implementation** — look at UI hierarchy, interaction flow, data persistence end-to-end.
4. **Then** evaluate each contract criterion with evidence from this exploration.

This prevents "checkbox testing" where the evaluator only tests the exact steps listed in the contract and misses obvious issues a real user would notice.

## Evaluation Dimensions

### 1. Contract Compliance (Pass/Fail gate)
Each contract criterion is individually verified. This is the hard gate for PASS/RETRY.

### 2. Product Depth (Advisory, reported in feedback)
- Are features real or stubs? (e.g., button exists but handler is a no-op)
- Does the feature work end-to-end? (create → persist → retrieve → display)
- Are edge cases handled? (empty state, long text, rapid clicks, back button)
- Is the feature complete enough to be useful, or just a skeleton?

### 3. Visual Design Quality (Advisory, web apps only)
- Information hierarchy: is the most important content prominent?
- Typography and spacing: consistent, intentional, readable?
- Color and contrast: accessible, cohesive palette?
- Layout: does it degrade gracefully on different viewport sizes?
- Polish: loading states, transitions, hover effects — does it feel intentional?
- **AI slop detection**: generic gradient hero, centered card with drop shadow, stock placeholder text, default component library look with zero customization. Flag these patterns.

### 4. Interaction Quality (Advisory, web apps only)
- Feedback: does the UI respond to user actions? (button press, form submit, loading)
- Error handling: does the user see helpful messages when something goes wrong?
- Navigation: can the user move through the app intuitively? Does the back button work?
- State management: does the app remember context across navigation?

### 5. Code Quality (Advisory, inferred from behavior)
- Console errors: any JS errors, unhandled promise rejections, 404s for assets?
- Performance: does the page load quickly? Any visible jank or layout shift?
- Network: are API calls succeeding? Any failed requests visible in console?

## Judgment Rules

### PASS
ALL contract items verified as passing. Score (X/10) is advisory only.

### RETRY
1 or more contract items FAIL. Return with specific feedback for Generator.
- Max retries per sprint: configurable via `max_retries` in config.md (default: 3)
- Feedback MUST include: what was tried, what was expected, what actually happened, steps to reproduce.

### PIVOT
RETRY count exceeds max_retries. Current approach cannot solve the problem.
- Evaluator must propose a concrete alternative approach
- Max pivots per sprint: configurable via `max_pivots` in config.md (default: 2)

### ESCALATE
PIVOT count exceeds max_pivots. Issue is logged and sprint is skipped.
- Write escalation details to `docs/harness/feedback/sprint-N-escalated.md`

## Trend Detection
Compare FAIL item count across last 2 iterations of the same sprint:
- Decreasing: continue with incremental improvement
- Same or increasing: signal for root cause investigation (orchestrator triggers systematic debugging)

## Scoring (Advisory)

Rate overall quality 1-10 as a reference metric. This does NOT affect PASS/RETRY/PIVOT judgment.

Scoring guide:
- **9-10**: All criteria pass, features feel complete, UI is polished, no console errors
- **7-8**: All criteria pass, minor rough edges (spacing, loading states, edge cases)
- **5-6**: Most criteria pass, some features feel incomplete or stub-like
- **3-4**: Multiple criteria fail, significant gaps in functionality
- **1-2**: Most criteria fail, app barely functional or crashes
