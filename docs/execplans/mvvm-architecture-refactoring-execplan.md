# Refactor Reading Flows to a Testable Layered Architecture

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`PLANS.md` exists at repository root. This plan must be maintained in accordance with `PLANS.md`.

## Purpose / Big Picture

After this change, contributors will be able to add or modify reading features without editing SwiftData persistence logic inside SwiftUI views. User-visible behavior remains the same (book registration, daily reading record, completion flow, date edits), but the execution path becomes: View -> ViewModel -> Domain Service -> Repository. This enables isolated tests for business rules and reduces regressions when changing one screen.

The change is observable when the core screens still behave the same in the simulator, while unit tests cover command flows (`registerBook`, `recordReading`, `completeBook`) without requiring UI rendering.

## Progress

- [x] (2026-02-12 09:23Z) Audited the current codebase and identified boundary violations in main reading flows.
- [x] (2026-02-12 09:23Z) Wrote architecture baseline in `ARCHITECTURE.md` and established migration design/steps in this ExecPlan.
- [x] (2026-02-12 09:34Z) Documented presentation architecture choice rationale in ADR `docs/decisions/adr-0001-presentation-architecture.md`.
- [x] (2026-02-12 09:44Z) Introduced composition root dependencies via `AppDependencies` and injected from `FiveGuyesApp`.
- [x] (2026-02-12 10:44Z) Migrated `MainHomeView` query state to `MainHomeViewModel` and completed command/query usage through `BookManagementService`.
- [x] (2026-02-12 10:06Z) Migrated registration flow command path to `registerBook` (`FinishGoalView` now writes through service).
- [x] (2026-02-12 10:18Z) Migrated completion/edit flows (`CompletionReviewView`, `UnfinishReadingView`, `ReadingDateEditView`) to service commands.
- [x] (2026-02-12 10:18Z) Removed remaining runtime usage of legacy `ReadingScheduleCalculator` from presentation views (boundary check in `Sources/Presentation/View` returns no matches for `ReadingScheduleCalculator(` and `modelContext` writes).
- [x] (2026-02-12 10:18Z) Expanded service tests for migrated flows (`updateCompletionReview`, `updateReadingPlan`) and verified full suite with `xcodebuild test`.
- [x] (2026-02-12 10:44Z) Decoupled major navigation payloads from SwiftData models by switching to `FGUserBook` (`dailyProgress`, `completionCelebration`, `completionReview`, `completionReviewUpdate`, `readingDateEdit`, `unfinishReading`).
- [x] (2026-02-12 13:40Z) Revalidated full test suite after query/payload refactor (`xcodebuild test` -> `** TEST SUCCEEDED **`).
- [x] (2026-02-12 13:44Z) Decoupled notification flow from SwiftData payload (`NotiSettingView`, `NotificationManager`, `NotificationType` now use `FGUserBook`; added `FGReadingProgress+Notification` helper extension).
- [x] (2026-02-12 13:44Z) Revalidated full test suite after notification decoupling (`xcodebuild test` -> `** TEST SUCCEEDED **`).

## Surprises & Discoveries

- Observation: The repository and service boundaries already exist and are usable.
  Evidence: `FiveGuyes/FiveGuyes/Sources/Domain/Service/BookManagementService.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/Repository/BookRepository.swift`.

- Observation: V2 calculators are implemented and well-tested, but legacy calculators are still invoked from Views.
  Evidence: `FiveGuyes/FiveGuyes/Sources/Model/V2/ReadingScheduleCalculatorV2.swift` and calls to `ReadingScheduleCalculator` in `MainHomeView.swift`, `DailyProgressView.swift`, `ReadingDateEditView.swift`.

- Observation: Navigation currently passes SwiftData models directly, which couples routing to persistence type details.
  Evidence: `Screens` enum in `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`.

- Observation: The first `xcodebuild test` attempt failed because destination/device defaults did not match the test target deployment level.
  Evidence: `iPhone 16` simulator 18.6 vs test deployment target 26.0 mismatch; rerun on `iPhone 17` simulator (26.2) succeeded.

- Observation: `completeBook` command has broader side effects (notification clear) than "소감 수정" use case requires.
  Evidence: `DefaultBookManagementService.completeBook` calls `notificationManager.clearRequests()`, so update-mode review save needed a dedicated command (`updateCompletionReview`) to avoid unrelated notification changes.

- Observation: Notification decoupling required moving "next reading day/pages" helper behavior from SwiftData model APIs to domain extension APIs.
  Evidence: Added `FGReadingProgress+Notification.swift` and switched `NotificationManager`/`NotificationType` inputs to `FGUserBook`.

## Decision Log

- Decision: Keep `DefaultBookManagementService` as the first migration façade instead of splitting into many use case classes immediately.
  Rationale: It minimizes churn and allows progressive migration screen-by-screen while preserving current tested behavior.
  Date/Author: 2026-02-12 / Codex

- Decision: Prioritize Home and Daily Progress flows before registration/completion flows.
  Rationale: These flows have the highest direct persistence coupling and drive most user sessions.
  Date/Author: 2026-02-12 / Codex

- Decision: Define architecture documentation before code migration.
  Rationale: Existing project instructions require architecture and ExecPlan alignment for significant refactors.
  Date/Author: 2026-02-12 / Codex

- Decision: Select Feature MVVM (with unidirectional state rules) instead of immediate MVI migration for phase 1.
  Rationale: It maximizes incremental migration safety and reuses existing service/repository seams; full MVI infra cost is deferred until complexity thresholds are met.
  Date/Author: 2026-02-12 / Codex

- Decision: Keep `DailyProgressView` and `MainHomeView` route payload types unchanged in this step while migrating command execution to service calls.
  Rationale: It isolates side-effect migration first (direct persistence removal) and avoids cross-screen route breakage during the same patch.
  Date/Author: 2026-02-12 / Codex

- Decision: Add dedicated service commands (`updateCompletionReview`, `updateReadingPlan`) instead of overloading `completeBook`.
  Rationale: `completeBook` includes completion-date mutation and global notification side effects; separating commands preserves behavior parity for update-mode review and reading-date edits.
  Date/Author: 2026-02-12 / Codex

- Decision: Keep notification-setting route (`notiSetting`) on SwiftData payload temporarily while decoupling all other major routes to `FGUserBook`.
  Rationale: Notification layer currently consumes `ReadingProgress`/`UserSettings` APIs from SwiftData model types; forcing full conversion in the same step would mix concerns and increase regression risk.
  Date/Author: 2026-02-12 / Codex

- Decision: Complete notification layer decoupling in a follow-up step by introducing domain-side helper methods (`findNextReadingDay`, `findNextReadingPagesPerDay`) on `FGReadingProgress`.
  Rationale: This removes the last presentation-level SwiftData dependency without reintroducing persistence coupling into UI flows.
  Date/Author: 2026-02-12 / Codex

## Outcomes & Retrospective

Current outcome: composition root wiring is in place (`AppDependencies` injected at app root), and core write paths in reading/registration/completion/date-edit flows now route through domain service boundaries:

- `DailyProgressView` -> `BookManagementService.recordReading`
- `MainHomeView` delete flow -> `BookManagementService.deleteBook`
- `MainHomeView` app-open reschedule -> `BookManagementService.rescheduleOnAppOpen`
- `FinishGoalView` -> `BookManagementService.registerBook`
- `CompletionReviewView` -> `BookManagementService.completeBook` / `updateCompletionReview`
- `UnfinishReadingView` -> `BookManagementService.completeBook`
- `ReadingDateEditView` -> `BookManagementService.updateReadingPlan`
- `CompletedBooksView` delete flow -> `BookManagementService.deleteBook`

Behavioral parity was validated through repeated `xcodebuild test` runs on iPhone 17 simulator (26.2), including after notification-layer decoupling. `MainHomeView` query state is ViewModel-owned, and all major navigation/notification payloads are now domain-typed (`FGUserBook`). Phase 1 boundary goal is met; optional follow-up work is additional ViewModel extraction for more complex screens.

## Context and Orientation

The current app starts at `FiveGuyes/FiveGuyes/Sources/App/FiveGuyesApp.swift` and routes through `NavigationRootView.swift` and `NavigationCoordinator.swift`. Core presentation flows are migrated off direct SwiftData access, including notification settings. Presentation now interacts through domain service/query boundaries and domain payload types.

Domain and data seams already exist:

- Service boundary: `BookManagementService` and `DefaultBookManagementService`
- Repository boundary: `BookRepository`, `SwiftDataBookRepository`, `MockBookRepository`
- Pure calculator path: `ReadingScheduleCalculatorV2`, `DateMathCalculator`, `PageMathCalculator`

In this repository, "composition root" means the single place where concrete implementations are created and injected (for example, repository + service instances created in App/Root and passed into ViewModels).

## Plan of Work

Milestone 1 introduces composition root wiring so presentation code receives dependencies through initialization and environment injection instead of creating persistence objects locally. This milestone should not change user-visible behavior.

Milestone 2 migrates read/write-heavy screens (`MainHomeView`, `DailyProgressView`) to ViewModel state and domain commands. Replace `@Query` and `modelContext` writes with service query/command calls and refresh logic.

Milestone 3 migrates registration screens to a single `registerBook` command path. Remove local schedule calculation and persistence from UI. Ensure notification side effects remain triggered from domain service after successful writes.

Milestone 4 migrates completion and date edit flows to service commands (`completeBook` and a settings update command added to the service if needed). Stop direct mutation of SwiftData model properties in Views.

Milestone 5 removes legacy runtime calculator usage from migrated flows and consolidates schedule behavior on V2 calculators. Preserve old code only if still needed by untouched screens.

Milestone 6 expands tests: ViewModel state transitions with mocked service, domain service command paths with mock repository, and existing repository tests retained as persistence contract checks.

## Concrete Steps

Run all commands from repository root `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`.

1. Audit and track direct SwiftData usage in presentation:

    rg -n "@Environment\\(\\\\.modelContext\\)|@Query|modelContext\\.|UserBookSchemaV2" FiveGuyes/FiveGuyes/Sources/Presentation

2. Build incremental migration branch state:

    git status --short --branch

3. Run unit tests after each milestone:

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "id=216C08ED-919D-4095-BF37-CB51C62F71B3"

4. If destination mismatch occurs, discover available destinations and rerun:

    xcodebuild -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -showdestinations

5. Verify boundary cleanup after each migrated flow:

    rg -n "@Environment\\(\\\\.modelContext\\)|@Query|ReadingScheduleCalculator\\(" FiveGuyes/FiveGuyes/Sources/Presentation/View

## Validation and Acceptance

Acceptance is behavior-first:

1. Home screen still shows reading/completed/empty states correctly and supports delete flow.
2. Daily progress input still supports target-exceeded warning, normal record, date extension, and completion transition.
3. Registration flow still saves a new book with an initial schedule and returns to root.
4. Completion flow still stores completion review and completion status.
5. Existing calculator and repository tests pass, and new ViewModel tests cover success/failure/loading states.

Technical acceptance:

- Migrated views no longer import SwiftData.
- Migrated views do not call `modelContext.insert/save/delete`.
- Migrated views do not call legacy `ReadingScheduleCalculator` directly.

## Idempotence and Recovery

The migration is additive and screen-by-screen. Each milestone can be repeated safely because the boundary checks are read-only (`rg`) and tests can be rerun without destructive effects. If a milestone introduces regressions, revert only the touched files for that milestone and rerun tests before continuing. Do not perform destructive repository resets; use targeted file-level rollback commands if needed.

## Artifacts and Notes

Expected boundary-check output should shrink as migration proceeds. Example before migration:

    FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift:23:@Environment(\.modelContext) private var modelContext
    FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift:35:@Query(...)
    FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/DailyProgressView.swift:8:import SwiftData

Expected service-boundary usage in migrated ViewModel code:

    let books = try await bookManagementService.fetchReadingBooks()
    let result = try await bookManagementService.recordReading(bookId: id, pagesRead: pages, readDate: date)

## Interfaces and Dependencies

The following interfaces must exist and be the main crossing points by completion:

- `BookManagementService` in `FiveGuyes/FiveGuyes/Sources/Domain/Service/BookManagementService.swift`:

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook
    func recordReading(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult
    func deleteBook(id: UUID) async throws
    func completeBook(id: UUID, completionDate: Date, review: String) async throws
    func updateCompletionReview(id: UUID, review: String) async throws
    func updateReadingPlan(bookId: UUID, startDate: Date, targetEndDate: Date, excludedReadingDays: [Date], today: Date) async throws
    func fetchReadingBooks() async throws -> [FGUserBook]
    func fetchCompletedBooks() async throws -> [FGUserBook]
    func fetchBookDetail(id: UUID) async throws -> FGUserBook
    func rescheduleOnAppOpen(bookId: UUID, today: Date) async throws

- `BookRepository` in `FiveGuyes/FiveGuyes/Sources/Domain/Repository/BookRepository.swift` remains the persistence contract for domain entities.

- `ReadingScheduleCalculatorV2` in `FiveGuyes/FiveGuyes/Sources/Model/V2/ReadingScheduleCalculatorV2.swift` remains the canonical schedule engine for migrated flows.

New interfaces to add during implementation:

- A presentation dependency container in App layer that exposes:

    var bookManagementService: BookManagementService { get }

- Feature ViewModels (for each migrated flow) that expose:

    load() async
    handleUserAction(...) async
    @Published or @Observable state

Revision Note (2026-02-12): Initial plan created to capture architecture design phase outcomes and define implementation milestones for the MV -> layered MVVM refactor.
Revision Note (2026-02-12): Added ADR linkage and explicit MVVM-vs-MVI decision rationale for presentation architecture selection.
Revision Note (2026-02-12): Updated with implementation progress (composition root + command-path migration), simulator destination discovery, and latest validation command/result.
Revision Note (2026-02-12): Completed registration/completion/date-edit command-path migration, removed presentation-side legacy calculator/modelContext writes, added new service commands/tests, and revalidated full test suite.
Revision Note (2026-02-12): Migrated `MainHomeView` query state to `MainHomeViewModel`, decoupled major route payloads to `FGUserBook`, and recorded notification-layer decoupling as the next remaining boundary task.
Revision Note (2026-02-12): Removed duplicate refactoring design memo (`docs/architecture-refactoring.md`) and consolidated canonical records into `ARCHITECTURE.md`, ADR, and this ExecPlan.
Revision Note (2026-02-12): Re-ran full test suite after latest payload/type migration and confirmed `** TEST SUCCEEDED **`.
Revision Note (2026-02-12): Completed notification-flow decoupling to `FGUserBook` (`NotiSettingView`, `NotificationManager`, `NotificationType`) and revalidated the full test suite with `** TEST SUCCEEDED **`.
