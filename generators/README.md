# Custom Generators

Create a new directory under `generators/` with a `SKILL.md` file.

## Example

```
generators/
└── my-generator/
    └── SKILL.md
```

## SKILL.md Format

```yaml
---
name: my-generator
description: Description of this generator's specialization
---

# My Generator

## Tech Stack
- [preferred technologies]

## Coding Standards
- [rules the generator should follow]

## Patterns
- [architectural patterns to use]
```

## Activate

Set in `docs/harness/config.md`:
```yaml
generator: my-generator
```
