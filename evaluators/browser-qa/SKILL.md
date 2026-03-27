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
# Install if needed
npm install -g @anthropic-ai/agent-browser

# Run against localhost
npx @anthropic-ai/agent-browser --url http://localhost:PORT
```

If agent-browser is not installed, the evaluator falls back to curl-based checks and notes the limitation in feedback.

## Process
1. Start dev server if not running (`npm run dev &` or project-specific command)
2. Poll `curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT` until 200 (max 30s)
3. Launch agent-browser pointing to localhost
4. For each contract criterion with type "browser":
   a. Navigate to the relevant page
   b. Interact with elements as specified (click, fill, submit)
   c. Verify expected state/content
   d. Check browser console for errors
   e. Capture screenshot as evidence
5. Stop dev server (kill by PID)

## Evidence Format
For each browser verification:
- URL visited
- Actions performed
- Expected vs actual result
- Screenshot path (if captured)
