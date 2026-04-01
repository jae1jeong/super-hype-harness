---
name: browser-qa-evaluator
description: Browser-based QA evaluator. Uses agent-browser (preferred) or Playwright MCP (fallback) to navigate, interact, screenshot, and verify.
---

# Browser QA Evaluator

Supplements the default evaluator with browser-based verification for web apps.

## Browser Tool Selection

**agent-browser first, Playwright MCP fallback:**

```bash
# Check agent-browser
which agent-browser > /dev/null 2>&1
```

If agent-browser available:
```bash
agent-browser open http://localhost:PORT
agent-browser snapshot                      # Page structure + refs (@e1, @e2...)
agent-browser click "@e1"                   # Click by ref
agent-browser fill "@e3" "test input"       # Fill form
agent-browser screenshot docs/harness/screenshots/round-N/{name}.png  # Save to round dir
agent-browser console                       # JS errors
agent-browser close                         # Close browser
```

If agent-browser NOT available, use **Playwright MCP**:
```
mcp__playwright__browser_navigate(url)      # Open URL
mcp__playwright__browser_snapshot()         # Page structure + refs
mcp__playwright__browser_click(element)     # Click element
mcp__playwright__browser_fill_form(...)     # Fill form
mcp__playwright__browser_take_screenshot()  # Capture evidence
mcp__playwright__browser_console_messages() # JS errors
mcp__playwright__browser_close()            # Close browser
```

## Process

1. Start dev server if not running
2. Wait for ready (poll with curl, max 30s)
3. Use browser tool to test:
   a. Open the app
   b. Snapshot — page structure and element refs
   c. For each contract criterion:
      - Navigate to the relevant page
      - Interact: click, fill, type by element ref
      - Verify: snapshot, check expected content/state
      - Evidence: screenshot for visual proof
      - **Read screenshot** with Read tool — visually analyze
      - Errors: check console for JS errors
4. Stop dev server

## Screenshot Storage

모든 스크린샷은 `docs/harness/screenshots/round-N/` 에 저장:
```bash
mkdir -p docs/harness/screenshots/round-N
agent-browser screenshot docs/harness/screenshots/round-N/criterion-01.png
```

## Evidence Format

For each verification:
- URL visited
- Actions performed (with element refs)
- Expected vs actual result
- Screenshot path (`docs/harness/screenshots/round-N/{name}.png`)
- Visual analysis from Read tool
