# ExecPlans

When writing complex features or significant refactors, use an ExecPlan from design to implementation.
Follow `./PLANS.md`.

# Architecture Docs

When creating or updating `ARCHITECTURE.md`, follow the structure and guidance in:
- `./docs/references/architecture-doc.md`
- `./docs/decisions/` (for architecture-level decisions)

# Git Conventions

For any Git-related action (branching, committing, PR preparation, merging), follow:
- `./docs/git/git-convention.md`

If implementation work starts while on `main`, `develop`, or `dev`, create a working branch immediately.

# File Header Convention

For newly added source files, use the repository owner's GitHub nickname in the header:

```swift
//  Created by zaehorang on <date>.
```

- Do not use assistant/tool names (e.g., `Codex`) in file headers.
- If a generated file includes a different creator name, normalize it before commit.
