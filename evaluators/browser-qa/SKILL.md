---
name: browser-qa-evaluator
description: Browser-based QA evaluator using vercel-labs/agent-browser. Navigates pages, interacts with elements, verifies state.
---

# Browser QA Evaluator

Supplements the default evaluator with browser-based verification for web apps.

## Prerequisites
- vercel-labs/agent-browser installed (`npx @anthropic-ai/agent-browser`)
- Dev server running on localhost

## Process
1. Start dev server if not running
2. Launch agent-browser pointing to localhost
3. For each contract criterion with type "browser":
   a. Navigate to the relevant page
   b. Interact with elements as specified
   c. Verify expected state/content
   d. Capture screenshot as evidence
4. Stop dev server when done

## Evidence Format
For each browser verification:
- URL visited
- Actions performed
- Expected vs actual result
- Screenshot path (if captured)
