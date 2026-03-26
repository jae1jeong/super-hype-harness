# Custom Evaluators

Create a new directory under `evaluators/` with a `SKILL.md` file.

## Example

```
evaluators/
└── my-evaluator/
    └── SKILL.md
```

## SKILL.md Format

```yaml
---
name: my-evaluator
description: What this evaluator checks
---

# My Evaluator

## Checks
- [what to verify]

## Evidence Format
- [how to report findings]
```

## Activate

Set in `docs/harness/config.md`:
```yaml
evaluator: my-evaluator
```
