# Remove BookManagementService Compatibility Layer and Align Preview/Test to UseCase Interfaces

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

After this change, all reading-flow boundaries (runtime, Preview, and ViewModel tests) use the same `...Using` UseCase interfaces. The compatibility facade `BookManagementService` and its adapter layers are removed. Contributors can now change UseCase interfaces in one boundary model without maintaining parallel service adapters.

This is observable by verifying that `BookManagementService` no longer appears under `Sources`/`FiveGuyesTests`, while existing preview/test scenarios continue to compile and the full test suite passes.

## Progress

- [x] (2026-02-15 18:54Z) Created working branch `feature/td-012-remove-bookmanagementservice` and confirmed clean working tree baseline.
- [x] (2026-02-15 18:54Z) Replaced Preview compatibility layer in `Sources/Presentation/Preview/PreviewSupport.swift` with a direct consolidated stub (`PreviewBookUseCaseStub`) that conforms to all `...Using` interfaces.
- [x] (2026-02-16 10:33Z) Added `PreviewBookUseCaseBinding` with `PreviewSupport.bindReadingBook`/`bindCompletedBook` and migrated ID-based previews to use shared `book + useCase` fixture binding.
- [x] (2026-02-15 18:54Z) Replaced `BookManagementServiceStub` and adapter wrappers in `FiveGuyesTests/Presentation/ViewModel/ViewModelTestSupport.swift` with direct UseCase stubs (`ReadingLibraryUseCaseStub`, `DailyReadingUseCaseStub`, `BookCompletionUseCaseStub`, `ReadingPlanUseCaseStub`, `BookRegistrationUseCaseStub`).
- [x] (2026-02-15 18:54Z) Migrated all affected ViewModel tests to new direct UseCase stubs while preserving existing assertions for call counts, errors, and duplicate-submit guards.
- [x] (2026-02-15 18:54Z) Removed `Sources/Domain/Service/BookManagementService.swift`.
- [x] (2026-02-15 18:54Z) Updated architecture/ADR/tech-debt docs to reflect complete removal of compatibility layer and TD-012 resolution.
- [x] (2026-02-15 18:55Z) Verified `BookManagementService` 0 references in `Sources`/`FiveGuyesTests` and passed full regression suite (`xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination \"platform=iOS Simulator,name=iPhone 17\"` -> `** TEST SUCCEEDED **`).

## Surprises & Discoveries

- Observation: Preview/test adapter logic was structurally duplicated because both wrapped one monolithic service protocol.
  Evidence: pre-change `PreviewSupport.swift` and `ViewModelTestSupport.swift` both had `BookManagementService -> ...Using` adapter sets.

- Observation: Converting to direct `...Using` stubs reduced indirection without changing ViewModel test intent.
  Evidence: each migrated test continues to assert the same call count and error-path outcomes against per-feature stubs.

- Observation: Consolidated preview stub default samples can produce ID mismatch against separately created preview `userBook` values.
  Evidence: ID-based previews (`DailyProgress`, `UnfinishReading`, `CompletionReview`, `ReadingDateEdit`) passed `book.id` into use cases while stub defaults generated different UUID books.

## Decision Log

- Decision: Remove `BookManagementService` completely instead of keeping a compatibility protocol for Preview/Test.
  Rationale: runtime boundary is already UseCase-first; keeping compatibility only in Preview/Test reintroduces dual-boundary maintenance cost.
  Date/Author: 2026-02-15 / Codex

- Decision: Keep Test stubs split by feature UseCase protocol, but consolidate Preview into one multi-conformance stub plus explicit binding helpers.
  Rationale: Test stubs benefit from independent control points, while Preview needs one mutable shared store and ID-safe fixture wiring for interaction stability.
  Date/Author: 2026-02-16 / Codex

## Outcomes & Retrospective

This work removes a transitional boundary that no longer provided runtime value. The repository now has one execution-boundary model for reading flows (`ViewModel -> ...Using`), which simplifies future refactors and reduces adapter drift risk.

Acceptance criteria were met: `BookManagementService` references are removed from runtime/test source trees and full regression tests succeeded.

## Context and Orientation

This repository’s reading flows are built around feature-level UseCase interfaces in `Sources/Domain/UseCase/BookManagement/*.swift`. Runtime dependency assembly happens in `Sources/App/AppDependencies.swift`, and navigation-level ViewModel construction happens in `Sources/Presentation/ViewModel/NavigationCoordinator.swift`.

Before this change, Preview and ViewModel tests still used a legacy compatibility protocol (`BookManagementService`) defined in `Sources/Domain/Service/BookManagementService.swift`, then converted to `...Using` via adapter types in:

- `Sources/Presentation/Preview/PreviewSupport.swift`
- `FiveGuyesTests/Presentation/ViewModel/ViewModelTestSupport.swift`

The implementation removes that compatibility protocol and adapters, and injects direct `...Using` stubs in both Preview and tests.

## Plan of Work

Edit Preview support first by replacing service-based compatibility with feature-level direct stubs. Then update each preview call site to instantiate those stubs directly.

Next, refactor test support by replacing the monolithic service stub and adapter wrappers with feature-level UseCase stubs preserving existing controllable behavior (errors, delays, gates, call counts, `today()` values).

After test support is updated, migrate each ViewModel test file to new stubs and retain assertion semantics unchanged.

Finally, remove the unused protocol file and synchronize architecture/ADR/tech-debt documents to the new canonical boundary model.

## Concrete Steps

Run from repository root `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`.

    git switch -c feature/td-012-remove-bookmanagementservice
    rg -n "BookManagementService|PreviewBookManagementService|BookManagementServiceStub|StubAdapter\(" FiveGuyes/FiveGuyes/Sources FiveGuyes/FiveGuyesTests

Apply code edits in:

- `FiveGuyes/FiveGuyes/Sources/Presentation/Preview/PreviewSupport.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainPreviewSupport.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/DailyProgressView.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/UnfinishReadingView.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionReviewView.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/ReadingDateEditView.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/FinishGoalView.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/ViewModelTestSupport.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/MainHomeViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/DailyProgressViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/CompletionReviewViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/ReadingDateEditViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/UnfinishReadingViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/FinishGoalViewModelTests.swift`

Remove protocol file:

    rm FiveGuyes/FiveGuyes/Sources/Domain/Service/BookManagementService.swift

Sync docs:

- `ARCHITECTURE.md`
- `docs/decisions/adr-0002-usecase-first-boundary.md`
- `docs/execplans/tech-debt-tracker.md`

## Validation and Acceptance

Run static verification:

    rg -n "BookManagementService" FiveGuyes/FiveGuyes/Sources FiveGuyes/FiveGuyesTests

Acceptance: command prints no matches.

Run full regression suite:

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17"

Acceptance: output contains `** TEST SUCCEEDED **`.

## Idempotence and Recovery

All edits are source-level and can be reapplied safely if interrupted. If a partial edit leaves compile failures, re-run search commands for `BookManagementService` and ensure all migrated files are in the updated set above.

If rollback is needed, restore branch state using normal Git revert/cherry-pick flows from this branch history; avoid destructive workspace resets.

## Artifacts and Notes

Expected static verification artifact:

    $ rg -n "BookManagementService" FiveGuyes/FiveGuyes/Sources FiveGuyes/FiveGuyesTests
    (no output)

Expected test artifact:

    ** TEST SUCCEEDED **

## Interfaces and Dependencies

No new external libraries are introduced.

The final boundary interfaces used by Preview and tests are:

- `ReadingLibraryUsing`
- `DailyReadingUsing`
- `BookCompletionUsing`
- `ReadingPlanUsing`
- `BookRegistrationUsing`

The compatibility interface removed by this plan is:

- `BookManagementService`

Plan revision note (2026-02-15): Initial plan created and updated to implementation-in-progress state for full compatibility-layer removal and boundary alignment requested by user.

Plan revision note (2026-02-15): Updated to implementation-complete state after static `BookManagementService` reference audit and full `xcodebuild test` verification succeeded.

Plan revision note (2026-02-16): Added Preview ID-alignment follow-up (`PreviewBookUseCaseBinding`) and updated decision/progress records to match consolidated preview stub design.
