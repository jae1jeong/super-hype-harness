# Evaluation Criteria

> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed and the generator got detailed feedback on what went wrong." — Anthropic

## Evaluation Approach

### Explore First, Judge Second

Before scoring ANY criterion, the evaluator MUST:
1. **Navigate the entire app freely** — not just the pages the contract mentions
2. **Screenshot key pages** and **read the screenshots** (Claude can see images)
3. **Study the implementation** — look at UI hierarchy, interaction flow, data persistence
4. **Then** evaluate each contract criterion with evidence

### Screenshot Analysis Protocol

For every screenshot taken:
1. `agent-browser screenshot` → saves image file
2. `Read` the image file → Claude visually analyzes the page
3. Record observations in feedback

This is what makes evaluation real — not just checking "element exists" but actually seeing and studying the result.

## Evaluation Dimensions

### 1. Contract Compliance (Hard gate — PASS/FAIL)
Each criterion has a **hard threshold**. If ANY ONE criterion fails, the sprint fails.
- Every criterion must be tested with actual evidence (command output, screenshot, API response)
- "PASS" requires proof, not assumption

### 2. Product Depth (Advisory)
> Adapted from Anthropic's criteria: "product depth, functionality, visual design, and code quality"

- Are features real or stubs? (button exists but handler is no-op)
- Does the feature work end-to-end? (create → persist → retrieve → display)
- Edge cases handled? (empty state, long text, rapid clicks, back button)
- Is the feature complete enough to be useful?

### 3. Visual Design Quality (Advisory, web apps only)
> "Design quality: does the design feel like a coherent whole or just parts? Does it have a mood or identity?"
> "Originality: how many custom decisions were made? Purple gradients over white cards is now a well-worn AI pattern."

- Information hierarchy: most important content prominent?
- Typography and spacing: consistent, intentional, readable?
- Color and contrast: accessible, cohesive palette?
- Layout: degrades gracefully on different viewports?
- Polish: loading states, transitions, hover effects
- **AI slop detection**: generic gradient hero, centered card with drop shadow, stock placeholder text, default component library look with zero customization

### 4. Interaction Quality (Advisory, web apps only)
> "Craft: how thoughtfully are typography, spacing, color, and contrast handled?"
> "Functionality: can you actually use it to complete a task?"

- Feedback: UI responds to user actions?
- Error handling: helpful messages on failure?
- Navigation: intuitive, back button works?
- State management: context preserved across navigation?

### 5. Code Quality (Advisory, inferred from behavior)
- Console errors: JS errors, unhandled promise rejections, 404s?
- Performance: page loads quickly? Visible jank or layout shift?
- Network: API calls succeeding? Failed requests?

## Judgment Rules

### PASS
ALL contract criteria verified as passing with evidence. Score is advisory.

### RETRY
1+ contract criteria FAIL. Feedback MUST include: what was tried, expected, actual, steps to reproduce.

### PIVOT
RETRY count exceeds max_retries and FAIL count is not decreasing. Evaluator must propose concrete alternative approach.

### ESCALATE
PIVOT count exceeds max_pivots. Log issue, move to next sprint.

## Trend Detection
Compare FAIL count across last 2 iterations:
- Decreasing: continue
- Same or increasing: recommend systematic debugging

## Scoring Guide (Advisory)

- **9-10**: All criteria pass, features complete, UI polished, no console errors
- **7-8**: All criteria pass, minor rough edges
- **5-6**: Most criteria pass, some features incomplete or stub-like
- **3-4**: Multiple criteria fail, significant gaps
- **1-2**: Most criteria fail, app barely functional

## Few-Shot Calibration

When evaluating, consider these examples of what each score looks like:

**Score 9**: Calendar app where you can create events, they persist, drag to reschedule works, mobile responsive, custom color scheme, smooth animations, no console errors.

**Score 6**: Calendar app where events create and display, but drag doesn't work, mobile layout breaks, default Material UI look, 3 console warnings.

**Score 3**: Calendar app where the grid renders but clicking "create event" does nothing, hardcoded sample events, no backend persistence.
