# TD-008/TD-009 Notification Contract and UseCase Boundary Alignment

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`PLANS.md` exists at repository root. This plan is maintained in accordance with `PLANS.md`.

## Purpose / Big Picture

After this change, notification scheduling awaits real completion (`clear -> morning -> night`) instead of launching detached work, and Presentation regains a strict `ViewModel -> UseCase` boundary for home notification trigger and book search flow. The same user-visible behavior is preserved, but async determinism, dependency semantics, and maintenance clarity are improved.

You can see it working by running the focused test suites for MainHome/NotiSetting/BookSearch and BookManagement UseCases and confirming `** TEST SUCCEEDED **`.

## Progress

- [x] (2026-02-15 16:06Z) Baseline checkpoint commit created on source branch and implementation branch `feature/td-008-009-usecase-boundary-refactor` was created from that commit.
- [x] (2026-02-15 16:16Z) Replaced fire-and-forget `Task` in `NotificationManager.setupAllNotifications` with awaited sequential execution.
- [x] (2026-02-15 16:19Z) Renamed notification dependency variables/parameters to `notificationService` while keeping type names (`NotificationManager`, `NotificationManaging`) unchanged.
- [x] (2026-02-15 16:21Z) Removed `MainHomeViewModel` infrastructure dependency and moved notification trigger through `ReadingLibraryUsing.setupNotifications(for:)`.
- [x] (2026-02-15 16:23Z) Added `BookSearchUseCase` and `BookSearchUsing`, then migrated `BookSearchViewModel` to UseCase injection.
- [x] (2026-02-15 16:24Z) Split `BookManagementUseCases.swift` into 3 related files (`Library+Registration`, `Daily+Plan`, `Completion`) without changing core type names.
- [x] (2026-02-15 16:27Z) Updated previews/tests/adapters to match new interfaces and naming.
- [x] (2026-02-15 16:28Z) Ran focused regression command for TD-008/009 scope and confirmed `** TEST SUCCEEDED **`.

## Surprises & Discoveries

- Observation: the project already uses `PBXFileSystemSynchronizedRootGroup`, so added/removed source files were picked up without manual `project.pbxproj` edits.
  Evidence: new Domain UseCase files compiled immediately in xcodebuild test run.

- Observation: MainHome regression tests could preserve existing assertions by routing `ReadingLibraryStubAdapter.setupNotifications(for:)` to the existing `NotificationManagerStub` instead of introducing a separate spy.
  Evidence: `MainHomeViewModelTests` continued validating call count/book ID with minimal test surface changes.

## Decision Log

- Decision: Keep `NotificationManager` and `NotificationManaging` type names, but rename dependency variables/parameters to `notificationService`.
  Rationale: aligns Service terminology convention without API churn risk.
  Date/Author: 2026-02-15 / Codex

- Decision: Add `setupNotifications(for:)` to `ReadingLibraryUsing` and have `MainHomeViewModel` call only this UseCase boundary.
  Rationale: restores strict Presentation boundary and removes direct infrastructure dependency.
  Date/Author: 2026-02-15 / Codex

- Decision: Introduce `BookSearchUsing` + `BookSearchUseCase` while keeping `BookSearching` as infrastructure protocol.
  Rationale: Presentation now depends on UseCase; infrastructure remains encapsulated in Domain UseCase.
  Date/Author: 2026-02-15 / Codex

- Decision: Split BookManagement UseCases by related feature groups (3 files), not per micro-usecase.
  Rationale: keeps navigation practical while reducing single-file cognitive load and merge pressure.
  Date/Author: 2026-02-15 / Codex

## Outcomes & Retrospective

TD-008 and TD-009 target scope is complete in production and test wiring. Notification async contract now matches `await` semantics, MainHome and BookSearch Presentation dependencies are UseCase-first, and BookManagement UseCases are split by related responsibilities.

Remaining architecture debt is now shifted to other open tracker items (e.g., TD-001/003/004/006/007), not this boundary/contract scope.

## Context and Orientation

Relevant production files:

- `FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`
- `FiveGuyes/FiveGuyes/Sources/App/AppDependencies.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotiSettingViewModel.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookSearch/BookSearchUseCase.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementLibraryAndRegistrationUseCases.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementDailyAndPlanUseCases.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementCompletionUseCases.swift`

Relevant tests:

- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/MainHomeViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/NotiSettingViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/BookSearchViewModelTests.swift`
- `FiveGuyes/FiveGuyesTests/Domain/UseCase/BookManagementUseCases*`

## Plan of Work

The implementation first fixed the async contract in `NotificationManager`, then aligned naming at dependency points. After that, home notification setup was moved behind `ReadingLibraryUsing`, and book search was wrapped in a new UseCase boundary. Finally, the oversized BookManagement UseCase file was split into three responsibility groups while preserving public type names and behavior.

## Concrete Steps

Working directory:

    /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys

Core verification command executed:

    xcodebuild test -project /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/MainHomeViewModelTests -only-testing:FiveGuyesTests/NotiSettingViewModelTests -only-testing:FiveGuyesTests/BookSearchViewModelTests -only-testing:FiveGuyesTests/BookManagementUseCasesQueryAndRegistrationTests -only-testing:FiveGuyesTests/BookManagementUseCasesDailyReadingTests -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests

## Validation and Acceptance

Acceptance criteria and result:

1. `NotificationManager.setupAllNotifications` has no internal detached `Task` and completes awaited sequentially: satisfied.
2. `MainHomeViewModel` does not inject `NotificationManaging`; notifications are triggered through `ReadingLibraryUsing`: satisfied.
3. `BookSearchViewModel` injects `BookSearchUsing`, not `BookSearching`: satisfied.
4. BookManagement UseCases are split into three related files with behavior unchanged: satisfied.
5. Focused tests for the affected boundaries succeed: satisfied (`** TEST SUCCEEDED **`).

## Idempotence and Recovery

These edits are source-level refactors and can be re-applied safely. If a later rebase introduces conflicts, resolve by preserving the new interface boundaries first (`ReadingLibraryUsing.setupNotifications`, `BookSearchUsing`), then re-run the same focused xcodebuild command.

## Artifacts and Notes

Test artifact location:

    /Users/zaehorang/Library/Developer/Xcode/DerivedData/FiveGuyes-bznqavdsjsxffbaoiasvqswdmngq/Logs/Test/Test-FiveGuyes-2026.02.16_01-27-03-+0900.xcresult

Outcome excerpt:

    ** TEST SUCCEEDED **

## Interfaces and Dependencies

Final interface changes in this scope:

- `protocol ReadingLibraryUsing`
  - added: `func setupNotifications(for readingBook: FGUserBook) async`

- `final class MainHomeViewModel`
  - init changed to `init(readingLibraryUseCase: any ReadingLibraryUsing)`
  - removed direct `NotificationManaging` dependency

- `protocol BookSearchUsing` (new)
  - `func fetchBooks(query: String) async throws -> [Book]`
  - `func fetchBookTotalPages(isbn: String) async throws -> Int`

- `struct BookSearchUseCase` (new)
  - wraps infrastructure `BookSearching`

- `final class BookSearchViewModel`
  - init changed to `init(bookSearchUseCase: any BookSearchUsing)`

- `final class AppDependencies`
  - renamed dependency property: `notificationManager` -> `notificationService`
  - added: `bookSearchUseCase: any BookSearchUsing`

- BookManagement UseCase file split:
  - removed: `BookManagementUseCases.swift`
  - added three grouped files for library/registration, daily/plan, completion

---

Plan revision note (2026-02-15): created and completed integrated TD-008/TD-009 ExecPlan with implementation and focused regression evidence.
