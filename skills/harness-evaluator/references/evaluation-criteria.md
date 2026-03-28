# Evaluation Criteria

> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed and the generator got detailed feedback on what went wrong." — Anthropic
> "Out of the box, Claude is a poor QA agent... would identify legitimate issues, then talk itself into deciding they weren't a big deal." — Anthropic

## Evaluation Approach

### Be Skeptical

Claude naturally skews positive when evaluating. Fight this tendency. If something looks questionable, it probably is. Do not talk yourself out of failures.

### Explore First, Judge Second

Before scoring:
1. **Navigate the entire app** — not just what the contract mentions
2. **Screenshot every page** and **Read the screenshots** — Claude can see images
3. **Study the implementation** — layout, flow, data persistence
4. **Then** evaluate criteria

### Screenshot Analysis Protocol

For every screenshot:
1. `agent-browser screenshot` → saves image file
2. `Read` the image file → visually analyze
3. Record observations in feedback

## Evaluation Dimensions

### 1. Contract Compliance (Hard gate — PASS/FAIL)

Each criterion has a **hard threshold**. If ANY ONE fails, the round fails.

### 2. Product Depth (Advisory)
- Stubs vs real features (hardcoded data, no-op handlers)
- End-to-end completeness (create → persist → retrieve → display)
- Edge cases (empty state, errors, long text, rapid clicks)

### 3. Design Quality (Advisory, web apps)

> "Does the design feel like a coherent whole rather than a collection of parts? Do colors, typography, layout, imagery, and other details combine to create a distinct mood and identity?"

### 4. Originality (Advisory, web apps)

> "Is there evidence of custom decisions, or is this template layouts, library defaults, and AI-generated patterns? Unmodified stock components—or telltale signs of AI generation like purple gradients over white cards—fail here."

### 5. Craft (Advisory)

> "Technical execution: typography hierarchy, spacing consistency, color harmony, contrast ratios. Most reasonable implementations do fine here by default; failing means broken fundamentals."

### 6. Functionality (Advisory)

> "Usability independent of aesthetics. Can users understand what the interface does, find primary actions, and complete tasks without guessing?"

## Judgment

### PASS
ALL contract criteria verified with evidence.

### FAIL
ANY contract criterion fails. Detailed feedback with:
- What was tried
- What was expected
- What actually happened
- Steps to reproduce
- Concrete fix direction

## Scoring Guide (Advisory, 1-10)

> "Calibrated using few-shot examples with detailed score breakdowns."

- **9-10**: All criteria pass, features complete, design cohesive with identity, no console errors
- **7-8**: All criteria pass, minor rough edges, functional but some generic patterns
- **5-6**: Most criteria pass, some stubs or incomplete features, default component look
- **3-4**: Multiple criteria fail, significant gaps, broken layouts
- **1-2**: Most criteria fail, app barely functional

### Few-Shot Examples

**Score 9**: Calendar app — events create/persist/display, drag-to-reschedule works, custom color scheme with distinct identity, smooth animations, mobile responsive, zero console errors.

**Score 6**: Calendar app — events create and display, drag doesn't work, mobile breaks, Material UI defaults with no customization, 3 console warnings.

**Score 3**: Calendar app — grid renders, "create event" button does nothing, hardcoded sample data, no backend, default template look.
