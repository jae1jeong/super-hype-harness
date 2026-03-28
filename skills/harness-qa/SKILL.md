---
name: harness-qa
description: Final QA verification after all sprints. Opens the app, tests full user journey, compares with references. Fixes bugs found.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Harness QA

Final end-to-end quality assurance after all sprints complete.

## Input

1. Read `docs/harness/config.md` (for app_type)
2. Read spec from `docs/harness/specs/` (for user journey and feature list)
3. If references exist: read `docs/harness/references/index.md` and reference images

## QA Strategy by App Type

### web

<HARD-GATE>
agent-browser is REQUIRED for web app QA. If not installed, run `npm install -g agent-browser && agent-browser install` before proceeding.
</HARD-GATE>

1. Start dev server in background (project-specific command from package.json)
2. Wait for server ready: poll with curl until 200 (max 30s)
3. Run agent-browser QA scenarios based on spec's user journey:
   ```bash
   agent-browser open http://localhost:PORT
   agent-browser snapshot
   agent-browser click "@e1"
   agent-browser fill "@e3" "test data"
   agent-browser screenshot   # Capture evidence
   agent-browser console      # Check for JS errors
   ```
4. **Screenshot and study every page** — use Read tool on each screenshot to visually analyze
5. For each scenario from the spec:
   - Navigate to the relevant page
   - Test core interactions (click, fill forms, submit)
   - Verify data persistence (create, navigate away, come back)
   - Check error handling (invalid input, 404 pages)
   - Check console for errors
   - Screenshot before/after for evidence
6. **Reference comparison** (if references exist):
   - Screenshot the implementation
   - Read reference images and implementation screenshots
   - Compare layout, design, interactions
   - Note remaining gaps
7. Stop dev server when done

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

## Reference Comparison (if applicable)
- Overall alignment: [percentage estimate]
- Matching elements: [list]
- Remaining gaps: [list]

## Bugs Found and Fixed
1. [bug description] - [fix applied] - [verified: yes/no]

## Remaining Issues
- [any unfixed issues]
```

Git commit after QA fixes.

## Handoff

After QA:
1. Update `docs/harness/state.md`:
   - `next_role: ship`
2. Announce: "QA 완료. state.md에 따라 ship 단계로 진행합니다."
