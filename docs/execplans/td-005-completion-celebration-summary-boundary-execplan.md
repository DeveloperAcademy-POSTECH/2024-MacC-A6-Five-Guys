# TD-005 Completion Celebration Summary Boundary

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

After this change, `CompletionCelebrationView` no longer computes completion-period date/page/day summary inside the SwiftUI view. The summary is now produced through `BookCompletionUseCase` using the domain today policy (`ReadingDateProviding`).

User-visible behavior remains the same (same celebration sentence format), but date source and summary calculation are now policy-aligned and testable in the domain boundary.

## Progress

- [x] (2026-02-15 14:11Z) Audited tech debt tracker and confirmed TD-005 as current highest-priority architecture debt target.
- [x] (2026-02-15 14:12Z) Added domain summary model/query contract to `BookCompletionUsing` and implemented summary calculation in `BookCompletionUseCase`.
- [x] (2026-02-15 14:13Z) Added `CompletionCelebrationViewModel` and moved `CompletionCelebrationView` to render-only summary consumption.
- [x] (2026-02-15 14:13Z) Updated navigation/preview/test adapters to match the updated `BookCompletionUsing` interface.
- [x] (2026-02-15 14:16Z) Added domain tests for completion summary calculation and future-start-date clamping.
- [x] (2026-02-15 14:16Z) Ran focused regression suites (`BookManagementUseCasesCompletionAndPlanTests`, `CompletionReviewViewModelTests`) with `** TEST SUCCEEDED **`.

## Surprises & Discoveries

- Observation: `CompletionCelebrationView` used `Date()` directly and compared start/end dates as formatted strings.
  Evidence: Previous implementation in `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift` had `Date().toKoreanDateString()` and `if startDateText > endDateText`.

- Observation: Existing architecture had no dedicated summary query for completion celebration, but `BookCompletionUseCase` already owned today-policy access (`todayProvider`).
  Evidence: `BookCompletionUseCase` previously used `todayProvider.today()` for complete-book command only.

## Decision Log

- Decision: Extend `BookCompletionUsing` with `completionCelebrationSummary(for:)` query instead of introducing another feature protocol.
  Rationale: Keeps completion feature dependency surface coherent and avoids additional DI expansion while preserving UseCase-first boundary.
  Date/Author: 2026-02-15 / Codex

- Decision: Keep date string formatting in the view and move only policy/date/page/day computation to domain use case.
  Rationale: Formatting is presentation concern; summary calculation is domain concern.
  Date/Author: 2026-02-15 / Codex

- Decision: Introduce `CompletionCelebrationViewModel` for the celebration screen.
  Rationale: Aligns with existing screen composition pattern (`NavigationCoordinator` creates ViewModel with UseCase injection).
  Date/Author: 2026-02-15 / Codex

## Outcomes & Retrospective

TD-005 objective was achieved for the targeted scope: completion summary logic was removed from `CompletionCelebrationView`, moved behind `BookCompletionUseCase`, and verified with focused domain/viewmodel regressions.

Residual debt remains outside this scope (e.g., other presentation-side calculations tracked under TD-003 and direct DayBoundary usage tracked under TD-004/TD-007 follow-up).

## Context and Orientation

Before this change, completion celebration summary lived inside `CompletionCelebrationView` and mixed:

- policy date source (`Date()`),
- string-based date ordering,
- page/day summary calculation.

Relevant files:

- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementUseCases.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`

Target architecture for this task:

- ViewModel/View invokes UseCase query.
- UseCase computes summary with domain today policy.
- View only formats/renders summary output.

## Plan of Work

First, add a domain summary value (`CompletionCelebrationSummary`) and expose a summary query on `BookCompletionUsing`. Implement the query in `BookCompletionUseCase` using `todayProvider.today()`, start-date clamping, and existing page math rules.

Second, add a dedicated `CompletionCelebrationViewModel` and update `CompletionCelebrationView` to consume `CompletionCelebrationSummary` from UseCase instead of computing values internally.

Third, update `NavigationCoordinator` and preview/test adapters for protocol conformance.

Fourth, add focused tests for summary calculation behavior and run regression suites.

## Concrete Steps

From repository root (`/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`):

1. Update completion use case interface and implementation in:
   - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementUseCases.swift`
2. Add view model:
   - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/CompletionCelebrationViewModel.swift`
3. Update celebration view and navigation wiring:
   - `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift`
   - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`
4. Update protocol adapters:
   - `FiveGuyes/FiveGuyes/Sources/Presentation/Preview/PreviewSupport.swift`
   - `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/ViewModelTestSupport.swift`
5. Add tests:
   - `FiveGuyes/FiveGuyesTests/Domain/UseCase/BookManagementUseCasesCompletionAndPlanTests.swift`
6. Validate:
   - `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests`
   - `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/CompletionReviewViewModelTests`

## Validation and Acceptance

Acceptance criteria:

1. `CompletionCelebrationView` no longer directly uses `Date()` for summary period calculation.
2. Summary start/end/date-page-day calculation is produced by `BookCompletionUseCase` via `completionCelebrationSummary(for:)`.
3. Domain tests confirm today-provider usage and future-start-date clamping.
4. Focused regression suites pass with `** TEST SUCCEEDED **`.

## Idempotence and Recovery

Changes are additive and safe to re-run. If any step fails, rerun the same test command after compile fixes. No data migration or destructive command is involved.

## Artifacts and Notes

Executed validation commands (all succeeded):

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/CompletionReviewViewModelTests

## Interfaces and Dependencies

Updated interface:

- `protocol BookCompletionUsing`
  - `func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary`

Added value model:

- `struct CompletionCelebrationSummary`
  - `startDate: Date`
  - `endDate: Date`
  - `totalReadingDays: Int`
  - `pagesPerDay: Int`

Added presentation mediator:

- `CompletionCelebrationViewModel`
  - depends on `any BookCompletionUsing`
  - exposes `summary(for:)`

---

Plan revision note (2026-02-15): created and completed TD-005 execution plan with implementation/test evidence for completion-celebration summary boundary refactor.
