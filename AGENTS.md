# ExecPlans

When writing complex features or significant refactors, use an ExecPlan from design to implementation.
Follow `./PLANS.md`.

# Architecture Docs

When creating or updating architecture documentation, follow:
- `./docs/decisions/`

# Git Conventions

For Git workflow (branching, commit), follow:
- `./docs/git/git-convention.md`

For PR workflow (preparation, writing, review), follow:
- `./docs/git/pr-convention.md`

When performing PR review, you must:
- Review full commit history and full diff against the base branch.
- Leave code findings as inline comments with `[P0]`~`[P3]` priority tags.
- Avoid top-level-only findings; use top-level comment only for summary/fallback with reason.
- If another agent is actively working on the same PR/branch, refresh and re-check latest `HEAD` before submitting review comments.

# Preview/Simulator Troubleshooting

If SwiftUI Preview is broken, or simulator build/run has runtime-state errors, check and apply:
- `./docs/setup/swiftui-preview-troubleshooting.md`
