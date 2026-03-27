---
name: browser-qa-evaluator
description: Browser-based QA evaluator using vercel-labs/agent-browser. Navigates pages, interacts with elements, verifies state.
---

# Browser QA Evaluator

Supplements the default evaluator with browser-based verification for web apps.

## Prerequisites
- [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) installed
- Dev server running on localhost

## How to invoke agent-browser

```bash
# Install (one-time)
npm install -g agent-browser
agent-browser install    # Downloads Chrome

# Core commands
agent-browser open http://localhost:PORT    # Open URL
agent-browser snapshot                      # Get page structure with element refs (@e1, @e2...)
agent-browser click "@e1"                   # Click element by ref
agent-browser fill "@e3" "test input"       # Fill form field
agent-browser screenshot                    # Capture evidence
agent-browser console                       # Check for JS errors
agent-browser close                         # Close browser
```

## Process
1. Start dev server if not running (project-specific command)
2. Wait for server ready (poll with curl until 200, max 30s)
3. Use agent-browser to test:
   a. `agent-browser open http://localhost:PORT` -- open the app
   b. `agent-browser snapshot` -- see page structure and element refs
   c. For each contract criterion with type "browser":
      - Navigate to the relevant page
      - Interact: `click`, `fill`, `type`, `hover` by element ref
      - Verify: take snapshot, check expected content/state
      - Evidence: `agent-browser screenshot` for visual proof
      - Errors: `agent-browser console` for JS errors
4. Stop dev server when done

## Evidence Format
For each browser verification:
- URL visited
- Actions performed
- Expected vs actual result
- Screenshot path (if captured)
