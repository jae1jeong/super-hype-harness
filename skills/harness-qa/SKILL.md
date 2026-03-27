---
name: harness-qa
description: Final QA verification after all sprints. Routes to browser QA (web), integration tests (cli), or test suite (library) based on app_type.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Harness QA

Final quality assurance after all sprints complete. Runs as Agent subprocess.

## Input
- Config: `docs/harness/config.md` (for app_type)
- Spec: `docs/harness/specs/` (for user journey and feature list)

## QA Strategy by App Type

### web
1. Start dev server in background (project-specific command from package.json)
2. Wait for server ready: poll with curl until 200 (max 30s)
3. Run [agent-browser](https://github.com/vercel-labs/agent-browser) QA scenarios based on spec's user journey:
   ```bash
   agent-browser open http://localhost:PORT
   agent-browser snapshot     # See page structure
   agent-browser click "@e1"  # Interact with elements
   agent-browser fill "@e3" "test data"
   agent-browser screenshot   # Evidence
   agent-browser console      # Check for JS errors
   ```
   For each scenario from the spec:
   - Navigate to the relevant page
   - Test core interactions (click, fill forms, submit)
   - Verify data persistence (create, navigate away, come back, still there?)
   - Check error handling (invalid input, 404 pages)
   - Check console for errors
   - Screenshot before/after for evidence
4. Stop dev server when done

If agent-browser is not installed, fall back to curl-based verification and note "DEGRADED" in QA report.

### cli
1. Build the project
2. Run integration tests if they exist
3. Execute the CLI with typical inputs and verify output
4. Test error cases (invalid input, missing args)

### library
1. Run the full test suite
2. Verify all public API functions work as documented
3. Check edge cases and error handling

## Bug Fix Loop
When a bug is found:
1. Document the bug (steps to reproduce, expected vs actual)
2. Fix the code
3. Re-verify the specific scenario
4. Continue QA from where we left off

## Output
Write QA report to `docs/harness/qa-report.md`:

```markdown
# QA Report

## App Type: [web|cli|library]
## Overall: [PASS|FAIL]

## Scenarios Tested
1. [scenario]: [PASS|FAIL] - [details]
2. ...

## Bugs Found and Fixed
1. [bug description] - [fix applied] - [verified: yes/no]

## Remaining Issues
- [any unfixed issues]
```

Git commit after QA fixes.
