# Refactor Reading Flows to a Testable Layered Architecture

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

After this change, contributors will be able to add or modify reading features without editing SwiftData persistence logic inside SwiftUI views. User-visible behavior remains the same (book registration, daily reading record, completion flow, date edits), but the execution path becomes: View -> ViewModel -> UseCase -> Repository/Infrastructure Service. This enables isolated tests for business rules and reduces regressions when changing one screen.

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
- [x] (2026-02-13 01:10) Verified post-merge baseline on `develop`: working tree clean, presentation boundary check (`@Query`, `modelContext`, `ReadingScheduleCalculator(`) returns no active runtime violations, full `xcodebuild test` passes on iPhone 17 simulator.
- [x] (2026-02-13 01:24) Extracted remaining service-calling screens (`DailyProgress`, `CompletionReview`, `ReadingDateEdit`, `FinishGoal`, `UnfinishReading`) into feature ViewModels so Views stop owning async command flow/state transitions.
- [x] (2026-02-13 01:26) Introduced notification settings ViewModel and abstraction seam (`NotiSettingViewModel`, `NotificationManaging`, `NotificationSettingsStoring`) so `NotiSettingView` no longer directly coordinates `NotificationManager`/`UserDefaultsManager`.
- [x] (2026-02-13 01:28) Added ViewModel-focused tests in `FiveGuyesTests/PresentationViewModelTests.swift` for new action/state paths (daily progress, completion review, date edit, finish goal, unfinish flow, notification settings).
- [x] (2026-02-13 01:30) Revalidated full test suite (`xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17"` -> `** TEST SUCCEEDED **`).
- [x] (2026-02-12 18:01Z) Moved Home notification setup side effect from `MainHomeView` to `MainHomeViewModel` and injected `NotificationManaging` from `AppDependencies`.
- [x] (2026-02-12 18:01Z) Added `MainHomeViewModel` test coverage (`setupNotificationsForCurrentBook`, `rescheduleOnAppOpen`) and revalidated full suite (`xcodebuild test ...` -> `** TEST SUCCEEDED **`).
- [x] (2026-02-12 18:26Z) Replaced remaining `configure(bookManagementService:)` pattern with constructor injection for feature ViewModels (`MainHome`, `DailyProgress`, `CompletionReview`, `ReadingDateEdit`, `UnfinishReading`, `FinishGoal`).
- [x] (2026-02-12 18:26Z) Moved ViewModel assembly to composition-aware creation points (`NavigationCoordinator`, `BookSettingsManagerView`) and updated navigation root to initialize coordinator with `AppDependencies`.
- [x] (2026-02-12 18:26Z) Updated `PresentationViewModelTests` for constructor injection and revalidated full suite (`xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17"` -> `** TEST SUCCEEDED **`).
- [x] (2026-02-13 03:31Z) Extended constructor injection/assembly consistency to notification settings flow: `NotiSettingView` no longer self-instantiates `NotiSettingViewModel`, and coordinator now assembles it from `AppDependencies`.
- [x] (2026-02-13 03:31Z) Revalidated architecture boundary checks (`configure(bookManagementService:)`, presentation `modelContext`/`@Query`/`ReadingScheduleCalculator(`) and full `xcodebuild test` on iPhone 17 (`** TEST SUCCEEDED **`).
- [x] (2026-02-12 18:53Z) Migrated book search flow to constructor-injected external API seam: `BookSearchViewModel` now depends on `BookSearching`, and `BookSettingsManagerView` assembles it via `AppDependencies.makeBookSearchStore()`.
- [x] (2026-02-12 18:55Z) Added `BookSearchViewModel` tests (search success/failure, total pages success/failure, selected book state) and revalidated full suite (`xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17"` -> `** TEST SUCCEEDED **`).
- [x] (2026-02-14 10:00Z) Reclassified legacy `Sources/Model` files by responsibility: domain calculation/value types moved under `Sources/Domain`, platform integrations moved under `Sources/Platform`, and API DTOs moved under `Sources/Store/Model`.
- [x] (2026-02-14 10:05Z) Validated folder reclassification with calculator-focused regression tests and synced architecture docs to the new folder map.
- [x] (2026-02-14 10:26Z) Added `Domain/UseCase/BookManagement/BookManagementUseCases.swift` and moved existing `DefaultBookManagementService` business logic into method-level UseCase executors.
- [x] (2026-02-14 10:28Z) Refactored `DefaultBookManagementService` into a facade that delegates each API to corresponding UseCase while preserving the existing `BookManagementService` contract.
- [x] (2026-02-14 10:29Z) Revalidated behavior parity with `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,id=216C08ED-919D-4095-BF37-CB51C62F71B3' -only-testing:FiveGuyesTests/DefaultBookManagementServiceTests` (`** TEST SUCCEEDED **`).
- [x] (2026-02-14 19:35Z) Audited remaining `ReadingDateCalculator`/`ReadingPagesCalculator` call sites and confirmed replacement paths by usage: schedule logic -> `ReadingScheduleCalculator`, date/page math helpers -> `DateMathCalculator`/`PageMathCalculator`.
- [x] (2026-02-14 19:38Z) Replaced all legacy calculator runtime references with `DateMathCalculator`/`PageMathCalculator`, updated notification/date-setting/finish-goal paths, and deleted legacy calculator files from `Sources/Util`.
- [x] (2026-02-14 19:39Z) Updated SwiftData `ReadingProgress` helper methods to delegate to domain models (`FGReadingProgress`, `FGUserSetting`) to remove duplicated calculation rules.
- [x] (2026-02-14 19:40Z) Added debt tracking document `docs/execplans/tech-debt-tracker.md` for day-boundary policy centralization and remaining SwiftData wrapper cleanup.
- [x] (2026-02-14 20:02Z) Accepted architecture decision ADR-0002 to adopt ViewModel -> UseCase direct dependency and reserve `Service` terminology for infrastructure providers.
- [x] (2026-02-14 20:03Z) Updated architecture map/invariants in `ARCHITECTURE.md` to reflect UseCase-first target boundary and transitional compatibility state.
- [x] (2026-02-14 20:05Z) Added UseCase boundary protocols (`...Using`) and made `BookManagementUseCases` structs conform so ViewModel can depend on feature-sized execution interfaces.
- [x] (2026-02-14 20:06Z) Started Phase 10 migration by wiring MainHome dependencies directly from UseCases in `AppDependencies` and `NavigationCoordinator`.
- [x] (2026-02-14 20:07Z) Revalidated partial Phase 10 change via focused regression tests (`PresentationViewModelTests`, `DefaultBookManagementServiceTests`) on iPhone 17 simulator (`** TEST SUCCEEDED **`).
- [x] (2026-02-14 20:17Z) Consolidated MainHome-related UseCase injection into a single feature boundary (`ReadingLibraryUsing`/`ReadingLibraryUseCase`) to reduce over-splitting at `MainHomeViewModel` and composition-root call sites.
- [x] (2026-02-14 20:17Z) Revalidated MainHome UseCase consolidation with focused regression tests (`PresentationViewModelTests`, `DefaultBookManagementServiceTests`) on iPhone 17 simulator (`** TEST SUCCEEDED **`).
- [x] (2026-02-14 20:21Z) Replaced temporary parallel home-list fetching with sequential fetch in `ReadingLibraryUseCase` to avoid potential `SwiftData ModelContext` concurrency hazards, and reran focused regression tests (`** TEST SUCCEEDED **`).
- [x] (2026-02-14 20:32Z) Renamed MainHome-oriented UseCase terms to domain-oriented names (`ReadingLibraryUsing`, `ReadingLibraryUseCase`, `ReadingLibrarySnapshot`) and aligned App/ViewModel dependency property names to the same convention.
- [x] (2026-02-14 20:32Z) Revalidated domain-focused naming refactor with focused regression tests (`PresentationViewModelTests`, `DefaultBookManagementServiceTests`) on iPhone 17 simulator (`** TEST SUCCEEDED **`).
- [x] (2026-02-14 20:40Z) Migrated remaining feature ViewModels (`DailyProgress`, `CompletionReview`, `ReadingDateEdit`, `UnfinishReading`, `FinishGoal`) to direct UseCase dependencies and removed production `BookManagementService` call paths from `Presentation/ViewModel` and `App`.
- [x] (2026-02-14 20:41Z) Replaced UseCase concrete notification coupling with infrastructure protocol `ReadingNotificationScheduling`, and wired `NotificationManager` conformance for composition-root injection.
- [x] (2026-02-14 20:42Z) Completed Phase 10 boundary validation (`rg` audits for service coupling/concrete notification usage + focused regression tests on `PresentationViewModelTests` and `DefaultBookManagementServiceTests`).
- [x] (2026-02-14 21:16Z) Resolved TD-001 by introducing centralized day-boundary policy (`DayBoundaryProviding`/`DefaultDayBoundaryPolicy`) and migrating direct `Date().adjustedDate()` usage to `DayBoundary.shared.adjustedNow()` + key generation to `DayBoundary.shared.adjustedDayKey(from:)`.
- [x] (2026-02-14 21:16Z) Added `DayBoundaryPolicyTests` and reran full regression suite (`xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,id=216C08ED-919D-4095-BF37-CB51C62F71B3'` -> `** TEST SUCCEEDED **`).
- [x] (2026-02-14 21:39Z) Reduced UseCase over-splitting by removing action-level `...Using` protocols and keeping only feature-boundary protocols for ViewModel dependencies.
- [x] (2026-02-14 21:39Z) Updated `BookManagementUseCases` to compose internal concrete action executors and revalidated with focused regression tests (`PresentationViewModelTests` had one flaky failure then passed on single rerun).
- [x] (2026-02-14 21:48Z) Converted service-level regression tests to usecase-level tests by migrating `DefaultBookManagementServiceTests.swift` -> `BookManagementUseCasesTests.swift` and validating the new suite with `xcodebuild test -only-testing:FiveGuyesTests/BookManagementUseCasesTests` (`** TEST SUCCEEDED **`).
- [x] (2026-02-14 22:10Z) Stabilized duplicate-submit flaky tests with deterministic gate/signal synchronization in `DailyProgressViewModelTests` and `CompletionReviewViewModelTests` (sleep/poll 의존 제거).
- [x] (2026-02-14 22:20Z) Added `ReadingDateProviding` and migrated Main/Daily/Completion/ReadingPlan ViewModel APIs to remove external `today/readDate/completionDate` injection.
- [x] (2026-02-14 22:28Z) Replaced notification next-page calculation with records-priority defensive logic (`max(record.pagesRead)+1` 우선, fallback/clamp 적용) and changed notification/date APIs to explicit `adjustedToday` inputs.
- [x] (2026-02-14 22:34Z) Added domain regression tests for notification calculations (`FGReadingProgressNotificationTests`) covering legacy/mixed/stale/no-record fixtures and NotificationType title/date behavior.
- [x] (2026-02-14 22:40Z) Removed runtime-unused `DefaultBookManagementService` implementation and updated architecture debt/docs (`tech-debt-tracker`, `ARCHITECTURE`, ADR-0002).

## Surprises & Discoveries

- Observation: The repository and service boundaries already exist and are usable.
  Evidence: `FiveGuyes/FiveGuyes/Sources/Domain/Service/BookManagementService.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/Repository/BookRepository.swift`.

- Observation: 계산기 경계는 구현 및 테스트가 되었지만, 일부 화면에서 구 계산기 직접 호출이 남아 있었던 시점이 있었다.
  Evidence: `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift` 도입 이후에도 `ReadingDateCalculator`/`ReadingPagesCalculator` 호출이 `FinishGoalViewModel`, `ReadingDateSettingView`, `ReadingDateEditView`에 남아 있었다.

- Observation: Navigation initially passed SwiftData models directly, which coupled routing to persistence type details.
  Evidence: `Screens` enum in `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`.

- Observation: The first `xcodebuild test` attempt failed because destination/device defaults did not match the test target deployment level.
  Evidence: `iPhone 16` simulator 18.6 vs test deployment target 26.0 mismatch; rerun on `iPhone 17` simulator (26.2) succeeded.

- Observation: `completeBook` command has broader side effects (notification clear) than "소감 수정" use case requires.
  Evidence: `DefaultBookManagementService.completeBook` calls `notificationManager.clearRequests()`, so update-mode review save needed a dedicated command (`updateCompletionReview`) to avoid unrelated notification changes.

- Observation: Notification decoupling required moving "next reading day/pages" helper behavior from SwiftData model APIs to domain extension APIs.
  Evidence: Added `FGReadingProgress+Notification.swift` and switched `NotificationManager`/`NotificationType` inputs to `FGUserBook`.

- Observation: Presentation boundary hardening alone was insufficient; action/state orchestration had to be extracted from several Views to unlock reliable feature-level tests.
  Evidence: 당시 `DailyProgressView`, `CompletionReviewView`, `FinishGoalView`, `ReadingDateEditView`, `UnfinishReadingView`, `NotiSettingView`가 async action handler와 submit/task guard를 View에 보유하고 있었다.

- Observation: `@Bindable` local bindings inside computed `some View` properties can require explicit `return` when additional local declarations are present.
  Evidence: `NotiSettingView.timePicker` needed explicit `return VStack { ... }` after introducing `@Bindable var bindableViewModel`.

- Observation: Even after Phase 2, Home entry flow still directly created `NotificationManager` in View, leaving one UI-layer side effect path outside ViewModel test coverage.
  Evidence: `MainHomeView` had `let notificationManager = NotificationManager()` and called `setupAllNotifications` before this update.

- Observation: Constructor injection from navigation assembly points required actor boundary alignment because dependencies and feature ViewModels are `@MainActor`.
  Evidence: `NavigationCoordinator.navigate(to:)` triggered main-actor isolation build errors until `NavigationCoordinator` itself was annotated `@MainActor`.

- Observation: Notification settings remained the last feature flow with in-View ViewModel instantiation after constructor injection migration.
  Evidence: `NotiSettingView` had `@State private var viewModel = NotiSettingViewModel()` while coordinator only passed route payload.

- Observation: `APIStore` requires runtime `API_KEY` resolution in initializer, so previews/tests need explicit stub injection once book search moves to constructor DI.
  Evidence: `APIStore.init` uses `Bundle.main.object(forInfoDictionaryKey: "API_KEY")` with `fatalError`, and `BookListView` preview now passes `BookSearchStorePreviewStub`.

- Observation: The Xcode project uses filesystem-synchronized groups, so path-level file moves were reflected in `project.pbxproj` automatically without manual file reference rewiring.
  Evidence: `PBXFileSystemSynchronizedRootGroup` is defined in `FiveGuyes/FiveGuyes.xcodeproj/project.pbxproj`.

- Observation: `BookManagementService` API 시그니처를 유지한 상태에서 내부 위임만 바꿔도 기존 서비스 테스트를 수정 없이 통과시킬 수 있었다.
  Evidence: `DefaultBookManagementServiceTests` 전체 케이스가 UseCase 분리 후에도 동일하게 `** TEST SUCCEEDED **`.

- Observation: 알림용 다음 목표 페이지 계산은 `lastReadPage`를 그대로 시작 페이지로 쓰면 `PageMathCalculator`의 페이지 유효성 규칙(1 이상)과 충돌할 수 있다.
  Evidence: `FGReadingProgress+Notification` 전환 시 `lastReadPage == 0` 케이스를 위해 `nextPage = max(lastReadPage + 1, 1)` 보정이 필요했다.

- Observation: UseCase 알림 의존은 concrete 타입 없이도 얇은 인프라 프로토콜(`ReadingNotificationScheduling`)로 분리 가능했고, 기존 동작을 유지한 채 조립 가능했다.
  Evidence: `BookManagementUseCases.swift`의 알림 의존 필드를 protocol 타입으로 교체했고, `Domain/Service/ReadingNotificationScheduling.swift` + `NotificationManager` extension으로 연결했다.

- Observation: ViewModel 생성자에 원자 UseCase를 다수 직접 주입하면 feature intent 대비 의존성이 과도하게 분산되어 조립/리뷰 비용이 증가한다.
  Evidence: 통합 전 `MainHomeViewModel`은 `FetchReadingBooksUsing`, `FetchCompletedBooksUsing`, `DeleteBookUsing`, `RescheduleOnAppOpenUsing` 4개를 개별 주입받았고 `NavigationCoordinator`/`AppDependencies`에서도 동일 fan-out이 중복되었다.

- Observation: `SwiftDataBookRepository`는 하나의 `ModelContext` 인스턴스를 공유하므로 동시 조회 최적화(`async let`)를 무분별하게 적용하면 안정성 리스크가 커질 수 있다.
  Evidence: `SwiftDataBookRepository`가 `modelContainer.mainContext`를 멤버로 보관해 모든 fetch/update에서 재사용한다.

- Observation: `notiSetting_timeChange_cancelsPreviousTask` 케이스는 단일/전체 실행에서 간헐적으로 상이한 결과를 보일 수 있어, 회귀 판정은 단일 재실행 + 전체 스위트 재검증을 함께 수행해야 안정적이었다.
  Evidence: 단일 재실행(`-only-testing:.../notiSetting_timeChange_cancelsPreviousTask`)은 성공했고, 이어서 전체 `xcodebuild test`도 성공했다.

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

- Decision: Start Phase 2 with "feature ViewModel extraction + ViewModel tests" instead of broad architecture replacement.
  Rationale: ADR-0001 selected incremental MVVM migration; the highest remaining risk is untested action orchestration in Views, not missing persistence boundaries.
  Date/Author: 2026-02-13 / Codex

- Decision: Introduce thin protocol seams for notification dependencies (`NotificationManaging`, `NotificationSettingsStoring`) in Presentation ViewModel layer.
  Rationale: Noti 설정 흐름의 비동기 상태 전이를 ViewModel 단위에서 테스트하기 위해, 시스템/저장소 호출을 최소 추상화로 분리했다.
  Date/Author: 2026-02-13 / Codex

- Decision: Extend composition root (`AppDependencies`) to provide notification dependency and inject it into `MainHomeViewModel`.
  Rationale: 홈 진입 시 알림 재설정도 ViewModel 책임으로 이관해 Presentation 계층의 직접 플랫폼 호출을 제거하고 테스트 가능성을 높인다.
  Date/Author: 2026-02-13 / Codex

- Decision: Standardize feature ViewModel dependency injection to constructor-based creation from coordinator/page assembly points instead of post-init `configure(...)`.
  Rationale: View lifecycle 시점의 누락/중복 구성 위험을 줄이고, View가 "이미 구성된 ViewModel"만 다루도록 강제해 아키텍처 경계를 명확히 유지한다.
  Date/Author: 2026-02-13 / Codex

- Decision: Apply the same coordinator-level ViewModel assembly rule to `NotiSettingViewModel` and expose `NotificationSettingsStoring` from `AppDependencies`.
  Rationale: 알림 설정 플로우도 동일한 composition root 정책으로 통일해, View/ViewModel 내부의 숨은 concrete 의존성 생성을 제거한다.
  Date/Author: 2026-02-13 / Codex

- Decision: Treat book search as the same composition-root dependency problem and replace `BookSearchViewModel`'s concrete `APIStore` construction with an injected `BookSearching` seam.
  Rationale: 등록 플로우도 feature ViewModel이 concrete 외부 API 객체를 직접 생성하지 않도록 통일해야 테스트 가능성/교체 가능성이 유지된다.
  Date/Author: 2026-02-12 / Codex

- Decision: Redefine folder boundaries explicitly by role (`Domain` for business calculators/entities, `Platform` for OS integrations, `Store` for external API DTOs) and stop treating `Sources/Model` as a domain bucket.
  Rationale: 현재 구조에서는 `Model`에 도메인 규칙과 플랫폼 코드가 혼재되어 경계가 흐려졌고, clean architecture 책임 분리를 파일 트리 수준에서 드러내야 이후 의존성 규칙을 강제하기 쉽다.
  Date/Author: 2026-02-14 / Codex

- Decision: Keep `BookManagementService` as an intermediate presentation-facing facade first, then retire it from production ViewModel call paths after UseCase boundaries stabilize.
  Rationale: 초기에는 변경 리스크를 줄이고, 이후에는 최종 목표(`ViewModel -> UseCase`)를 충족하기 위해 단계적 전환이 필요했다.
  Date/Author: 2026-02-14 / Codex

- Decision: Remove `ReadingDateCalculator` and `ReadingPagesCalculator` entirely after replacing all runtime call sites with `DateMathCalculator` and `PageMathCalculator`.
  Rationale: 계산 규칙 이중화를 제거하고, `ReadingScheduleCalculator`의 내부 수학 규칙과 화면/알림 계산 경로를 동일한 유틸 계층으로 맞추기 위함이다.
  Date/Author: 2026-02-14 / Codex

- Decision: Keep SwiftData `ReadingProgress` convenience methods temporarily but delegate them to domain-model methods.
  Rationale: 즉시 호출부를 전면 교체하지 않고도 계산 규칙 중복을 제거하면서, 이후 단계에서 데이터 모델의 도메인 래퍼를 안전하게 삭제할 수 있다.
  Date/Author: 2026-02-14 / Codex

- Decision: Adopt `ViewModel -> UseCase` direct dependency as the target architecture and treat `BookManagementService` as a transitional adapter only.
  Rationale: 화면 의존성을 기능 단위로 축소하고, 도메인 실행 경계(UseCase)와 인프라 제공자(Service)의 의미를 명확히 분리하기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Reserve `Service` naming for infrastructure providers (`NotificationManaging`, settings store, external API, time policy), not domain command/query facade.
  Rationale: 네이밍 의미를 단일화해 경계 이해/리뷰/테스트 조립 비용을 줄이기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Keep atomic UseCases internally but expose a feature-composed UseCase boundary (`ReadingLibraryUsing`) to the corresponding ViewModel.
  Rationale: UseCase-first 아키텍처를 유지하면서도 ViewModel 생성자 fan-out을 줄여 과분리 체감을 완화하고, 기능 단위 의존성 경계를 명확히 하기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Keep `ReadingLibraryUsing.fetchLibrarySnapshot()` as sequential reads instead of parallel `async let`.
  Rationale: 현재 repository 구현이 shared `ModelContext` 기반이라 안정성 우선으로 동시성 최적화를 보류하고, 기능 통합 자체(의존성 fan-out 축소)에 집중하기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: UseCase and payload naming should follow domain language rather than view/screen names.
  Rationale: 도메인 경계는 UI 구조 변화와 독립적으로 유지되어야 하며, 네이밍을 도메인 기준으로 통일하면 재사용성과 계층 의미가 명확해진다.
  Date/Author: 2026-02-14 / Codex

- Decision: Keep `BookManagementService` only as compatibility for preview/test adapters after Phase 3 completion, and prohibit adding new production dependencies to it.
  Rationale: 운영 경계는 UseCase-first로 고정하고, 프리뷰/테스트의 점진 전환 비용만 제한적으로 감당하기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Centralize 04:00 day-boundary policy behind `DayBoundaryProviding` and route adjusted-date/day-key calculations through that policy.
  Rationale: 산재한 날짜 경계 계산식을 단일 정책으로 통합해 규칙 드리프트를 방지하고, 운영 경계의 시간 정책 의도를 명확히 하기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Keep only feature-level UseCase protocols at the Presentation boundary and collapse action-level UseCase protocols to internal concrete executors.
  Rationale: 경계 의미(`ViewModel -> Feature UseCase`)는 유지하면서 프로토콜 수를 줄여 과분리로 인한 조립/인지 비용을 낮추기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Enforce 04:00 day-boundary injection at ViewModel APIs via `ReadingDateProviding` and remove externally injected `today/readDate/completionDate` parameters from key presentation actions.
  Rationale: 날짜 경계 규칙을 호출부에 노출하지 않고 단일 UseCase 경계로 강제해 오용 가능성을 줄이기 위함.
  Date/Author: 2026-02-14 / Codex

- Decision: Remove `DefaultBookManagementService` implementation and keep only the `BookManagementService` protocol for preview/test adapters.
  Rationale: 운영 경로에서 미사용인 중복 계층을 제거하고 UseCase-first 경계를 명확히 유지하기 위함.
  Date/Author: 2026-02-14 / Codex

## Outcomes & Retrospective

Current outcome: composition root wiring is in place (`AppDependencies` injected at app root), and production presentation flows now route through feature UseCase boundaries:

- `MainHomeViewModel` -> `ReadingLibraryUsing`
- `DailyProgressViewModel` -> `DailyReadingUsing`
- `CompletionReviewViewModel` / `UnfinishReadingViewModel` -> `BookCompletionUsing`
- `ReadingDateEditViewModel` -> `ReadingPlanUsing`
- `FinishGoalViewModel` -> `BookRegistrationUsing`

`BookManagementService` is no longer used by production `App`/`Presentation/ViewModel` call paths and is retained only as a compatibility layer for preview/test adapters during transition.

Behavioral parity was validated through repeated `xcodebuild test` runs on iPhone 17 simulator (26.2), including after notification-layer decoupling and a post-merge baseline rerun on 2026-02-13. `MainHomeView` query state is ViewModel-owned, and all major navigation/notification payloads are now domain-typed (`FGUserBook`).

Phase 2 outcome (2026-02-13): action-heavy screens now route through feature ViewModels (`DailyProgressViewModel`, `CompletionReviewViewModel`, `ReadingDateEditViewModel`, `FinishGoalViewModel`, `UnfinishReadingViewModel`, `NotiSettingViewModel`) and no longer execute domain service commands directly in View button handlers. New ViewModel tests were added in `FiveGuyesTests/PresentationViewModelTests.swift`, and full regression tests pass (`** TEST SUCCEEDED **`).

Phase 3 incremental outcome (2026-02-13): Home entry flow notification setup also moved behind ViewModel boundary (`MainHomeViewModel.setupNotificationsForCurrentBook`), so `MainHomeView` no longer creates or calls `NotificationManager` directly. Regression behavior was validated with added Home ViewModel tests and a full `xcodebuild test` pass on iPhone 17 simulator.

Phase 4 incremental outcome (2026-02-13): feature ViewModels now receive `BookManagementService` through constructors and are created at navigation/page assembly points, removing runtime `configure(...)` calls from Views. `NavigationCoordinator` is now `@MainActor` to align with dependency/viewmodel isolation rules, and all regression tests still pass.

Phase 5 incremental outcome (2026-02-13): notification settings flow now follows the same constructor injection assembly model as other features. `NotiSettingView` receives a preconfigured `NotiSettingViewModel` from `NavigationCoordinator`, and its dependencies (`NotificationManaging`, `NotificationSettingsStoring`) are provided by `AppDependencies`.

Phase 6 incremental outcome (2026-02-12): book registration search flow now follows constructor injection as well. `BookSearchViewModel` no longer constructs `APIStore` directly, `BookSettingsManagerView` assembles it using `AppDependencies.makeBookSearchStore()`, and dedicated `PresentationViewModelTests` coverage was added for search and total-page query behavior.

Phase 7 incremental outcome (2026-02-14): folder boundaries were reclassified by responsibility. `ReadingScheduleCalculator` and `ReadingRecord` moved out of `Sources/Model` into `Sources/Domain`, notification/system/analytics implementations moved into `Sources/Platform`, and `APIBooksModel` moved into `Sources/Store/Model` to keep data source concerns localized.

Phase 8 incremental outcome (2026-02-14): `DefaultBookManagementService` now acts as a facade delegating to `Domain/UseCase/BookManagement` executors. The external service contract stayed unchanged, and command/query behavior parity was confirmed by rerunning `DefaultBookManagementServiceTests`.

Phase 9 incremental outcome (2026-02-14): legacy calculators (`ReadingDateCalculator`, `ReadingPagesCalculator`) were fully removed from runtime code paths. Presentation/notification/date helper flows now use `DateMathCalculator` and `PageMathCalculator`, while schedule orchestration remains centralized in `ReadingScheduleCalculator`. SwiftData `ReadingProgress` wrappers were changed to domain delegation to prevent rule drift.

Phase 10 completion outcome (2026-02-14): architecture target `ViewModel -> UseCase -> Repository/Infrastructure Service` was fully applied to production call paths. `AppDependencies` now assembles feature-composed UseCases (`ReadingLibraryUseCase`, `DailyReadingUseCase`, `BookCompletionUseCase`, `ReadingPlanUseCase`, `BookRegistrationUseCase`), and all target ViewModels consume these boundaries directly. UseCase 알림 의존도 `ReadingNotificationScheduling` 프로토콜로 추상화되어 concrete `NotificationManager` 결합이 제거되었다. Regression checks (`PresentationViewModelTests`, `DefaultBookManagementServiceTests`) remained green.

Phase 11 incremental outcome (2026-02-14): TD-001(하루 경계 04:00 정책 중앙화)을 완료했다. `DayBoundaryProviding`/`DefaultDayBoundaryPolicy`를 도입해 adjusted-date/day-key 계산 경로를 단일화했고, `Date().adjustedDate()` 직접 호출은 운영 코드에서 제거되었다. `DayBoundaryPolicyTests`를 추가해 경계 시각(03:59/04:00)과 Date 확장 위임 동작을 검증했고 전체 테스트 스위트가 통과했다.

Phase 12 incremental outcome (2026-02-14): UseCase 과분리를 줄이기 위해 action 단위 `...Using` 프로토콜을 제거하고 내부 concrete 실행 단위로 통합했다. Presentation 경계는 기존 feature-sized 프로토콜(`ReadingLibraryUsing`, `DailyReadingUsing`, `BookCompletionUsing`, `ReadingPlanUsing`, `BookRegistrationUsing`)을 유지해 아키텍처 의도를 보존했다.

Phase 13 incremental outcome (2026-02-14): 테스트 경계를 UseCase-first 아키텍처에 맞춰 정렬했다. 기존 `DefaultBookManagementServiceTests`를 `BookManagementUseCasesTests`로 전환해, 등록/기록/완독/계획수정/조회 시나리오를 feature/action UseCase 실행 기준으로 검증한다. 호환 서비스는 운영 경로에서 이미 제외되어 테스트의 주 검증 대상도 UseCase 실행 단위로 이동했다.

Phase 14 incremental outcome (2026-02-14): 날짜 경계 규칙을 `ReadingDateProviding`로 강제해 Main/Daily/Completion/ReadingPlan ViewModel API에서 외부 날짜 주입 파라미터를 제거했다. 동시에 알림 페이지 계산은 records 우선 방어 로직으로 교체하고(`max(record.pagesRead)+1`), `DefaultBookManagementService` 구현체를 제거해 중복 계층을 정리했다.

## Context and Orientation

The current app starts at `FiveGuyes/FiveGuyes/Sources/App/FiveGuyesApp.swift` and routes through `NavigationRootView.swift` and `NavigationCoordinator.swift`. Core presentation flows are migrated off direct SwiftData access, including notification settings. Production Presentation now uses a consistent execution boundary: feature ViewModels depend on UseCase interfaces directly.

Domain and data seams already exist:

- UseCase execution boundary: `Domain/UseCase/BookManagement/*`
- Compatibility facade boundary (preview/test adapters): `BookManagementService` and `DefaultBookManagementService`
- Repository boundary: `BookRepository`, `SwiftDataBookRepository`, `MockBookRepository`
- Pure calculator path: `ReadingScheduleCalculator`, `DateMathCalculator`, `PageMathCalculator`

In this repository, "composition root" means the single place where concrete implementations are created and injected (for example, repository + service instances created in App/Root and passed into ViewModels).

## Plan of Work

Milestone 1 introduces composition root wiring so presentation code receives dependencies through initialization and environment injection instead of creating persistence objects locally. This milestone should not change user-visible behavior.

Milestone 2 migrates read/write-heavy screens (`MainHomeView`, `DailyProgressView`) to ViewModel state and domain commands. Replace `@Query` and `modelContext` writes with service query/command calls and refresh logic.

Milestone 3 migrates registration screens to a single `registerBook` command path. Remove local schedule calculation and persistence from UI. Ensure notification side effects remain triggered from domain service after successful writes.

Milestone 4 migrates completion and date edit flows to service commands (`completeBook` and a settings update command added to the service if needed). Stop direct mutation of SwiftData model properties in Views.

Milestone 5 removes legacy runtime calculator usage from migrated flows and consolidates schedule behavior on V2 calculators. Preserve old code only if still needed by untouched screens.

Milestone 6 expands tests: ViewModel state transitions with mocked service, domain service command paths with mock repository, and existing repository tests retained as persistence contract checks.

### Phase 2 (Post-Boundary Hardening) Milestones

Milestone 7 extracts async command/query orchestration out of action-heavy Views into feature ViewModels:

- `DailyProgressView` -> `DailyProgressViewModel`
- `CompletionReviewView` -> `CompletionReviewViewModel`
- `ReadingDateEditView` -> `ReadingDateEditViewModel`
- `FinishGoalView` -> `FinishGoalViewModel`
- `UnfinishReadingView` -> `UnfinishReadingViewModel`

Milestone 8 introduces notification-settings orchestration in a dedicated ViewModel (`NotiSettingViewModel`) with testable abstraction seams for notification authorization/request updates and local preference persistence.

Milestone 9 adds test coverage for new ViewModels (happy path + failure + duplicate submit/task guard) and keeps existing service/repository tests as regression backstop.

Milestone 10 removes the remaining Home-side notification orchestration from `MainHomeView` and migrates it into `MainHomeViewModel` with composition-root injection + ViewModel tests.

Milestone 11 removes post-init ViewModel configuration for book-management flows by adopting constructor injection and coordinator-level ViewModel assembly.

Milestone 12 migrates the book-search flow (`BookSearchViewModel`, `BookSearchView`, `BookSettingsManagerView`) to composition-root-injected search dependency (`BookSearching`) and adds dedicated ViewModel tests for search and total-page lookup behavior.

### Phase 3 (UseCase-First Boundary) Milestones

Milestone 13 defines UseCase interfaces and feature-level dependency bundles for Presentation. AppDependencies should assemble these bundles directly instead of exposing only `BookManagementService`.

Milestone 14 migrates feature ViewModels from `BookManagementService` dependency to explicit UseCase dependencies. Start from `MainHomeViewModel`, then command-heavy flows (`DailyProgress`, `CompletionReview`, `ReadingDateEdit`, `UnfinishReading`, `FinishGoal`).

Milestone 15 changes UseCase implementations to depend on infrastructure service protocols (for notifications/time policy) rather than concrete `NotificationManager`, then wires concrete implementations in composition root.

Milestone 16 retires `BookManagementService` from production call paths and keeps it only as temporary compatibility adapter (or removes it when all call sites are migrated), with full regression test verification.

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

6. Audit remaining facade usage before/after Phase 3:

    rg -n "BookManagementService" FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel FiveGuyes/FiveGuyes/Sources/App

7. Audit concrete notification coupling inside UseCases:

    rg -n "NotificationManager" FiveGuyes/FiveGuyes/Sources/Domain/UseCase

## Validation and Acceptance

Acceptance is behavior-first:

1. Home screen still shows reading/completed/empty states correctly and supports delete flow.
2. Daily progress input still supports target-exceeded warning, normal record, date extension, and completion transition.
3. Registration flow still saves a new book with an initial schedule and returns to root.
4. Completion flow still stores completion review and completion status.
5. Existing calculator and repository tests pass, and new ViewModel tests cover success/failure/loading states.
6. Notification setting 화면에서 권한/시간/토글 변화 시 기존과 동일한 사용자 동작을 유지한다.

Technical acceptance:

- Migrated views no longer import SwiftData.
- Migrated views do not call `modelContext.insert/save/delete`.
- Migrated views do not call legacy `ReadingScheduleCalculator` directly.
- Phase 2 target Views do not directly call `BookManagementService`/`NotificationManager` in button action handlers; ViewModel methods own async orchestration and submission guards.
- `MainHomeView` does not construct `NotificationManager`; notification side effects are triggered only via `MainHomeViewModel`.
- Views do not call `configure(bookManagementService:)`; affected feature ViewModels are created with dependencies at initialization.
- `NotiSettingView` does not instantiate `NotiSettingViewModel` directly; coordinator/composition root provides its dependencies.
- `BookSearchViewModel` does not instantiate `APIStore` directly; book search dependency is injected via `BookSearching`.
- Phase 3 target ViewModels do not depend on `BookManagementService`; they depend on required UseCase interfaces only.
- Domain UseCase implementations do not depend on concrete `NotificationManager`; they depend on infrastructure protocols.

## Idempotence and Recovery

The migration is additive and screen-by-screen. Each milestone can be repeated safely because the boundary checks are read-only (`rg`) and tests can be rerun without destructive effects. If a milestone introduces regressions, revert only the touched files for that milestone and rerun tests before continuing. Do not perform destructive repository resets; use targeted file-level rollback commands if needed.

## Artifacts and Notes

Expected boundary-check output should shrink as migration proceeds. Example before migration:

    FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift:23:@Environment(\.modelContext) private var modelContext
    FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift:35:@Query(...)
    FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/DailyProgressView.swift:8:import SwiftData

Expected usecase-boundary usage in migrated ViewModel code:

    let books = try await fetchReadingBooksUseCase.execute()
    let result = try await recordReadingUseCase.execute(bookId: id, pagesRead: pages, readDate: date)

## Interfaces and Dependencies

The following interfaces must exist and be the main crossing points by completion:

- UseCase interfaces for Presentation boundary (feature-sized contracts):

    struct ReadingLibrarySnapshot { let readingBooks: [FGUserBook]; let completedBooks: [FGUserBook] }

    protocol ReadingLibraryUsing {
        func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot
        func deleteBook(id: UUID) async throws
        func rescheduleOnAppOpen(bookId: UUID, today: Date) async throws
    }

    protocol DailyReadingUsing {
        func recordReading(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult
    }

    protocol BookCompletionUsing {
        func completeBook(id: UUID, completionDate: Date, review: String) async throws
        func updateCompletionReview(id: UUID, review: String) async throws
    }

    protocol ReadingPlanUsing {
        func updateReadingPlan(
            bookId: UUID,
            startDate: Date,
            targetEndDate: Date,
            excludedReadingDays: [Date],
            today: Date
        ) async throws
    }

    protocol BookRegistrationUsing {
        func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook
    }

- `BookRepository` in `FiveGuyes/FiveGuyes/Sources/Domain/Repository/BookRepository.swift` remains the persistence contract for domain entities.

- `ReadingScheduleCalculator` in `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift` remains the canonical schedule engine for migrated flows.

Implemented interfaces and containers:

- App-layer dependency container (`AppDependencies`) now exposes:

    var readingLibraryUseCase: ReadingLibraryUsing { get }
    var dailyReadingUseCase: DailyReadingUsing { get }
    var bookCompletionUseCase: BookCompletionUsing { get }
    var readingPlanUseCase: ReadingPlanUsing { get }
    var bookRegistrationUseCase: BookRegistrationUsing { get }
    var notificationManager: NotificationManaging { get }
    var notificationSettingsStore: NotificationSettingsStoring { get }
    func makeBookSearchStore() -> BookSearching

- Book-search seam in `FiveGuyes/FiveGuyes/Sources/Store/APIStore.swift`:

    protocol BookSearching {
        func fetchBooks(query: String) async throws -> [Book]
        func fetchBookTotalPages(isbn: String) async throws -> Int
    }

- Feature ViewModels (for each migrated flow) that expose:

    load() async
    handleUserAction(...) async
    @Published or @Observable state

- Book-management use case executor set in `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementUseCases.swift`:

    struct FetchReadingBooksUseCase
    struct FetchCompletedBooksUseCase
    struct FetchBookDetailUseCase
    struct RescheduleOnAppOpenUseCase
    struct RegisterBookUseCase
    struct RecordReadingUseCase
    struct DeleteBookUseCase
    struct CompleteBookUseCase
    struct UpdateCompletionReviewUseCase
    struct UpdateReadingPlanUseCase
    struct ReadingLibraryUseCase
    struct DailyReadingUseCase
    struct BookCompletionUseCase
    struct ReadingPlanUseCase
    struct BookRegistrationUseCase

Internal composition rule:

- Action executors (`FetchReadingBooksUseCase`, `RecordReadingUseCase` 등)는 내부 concrete 타입으로 유지하고 별도 `...Using` 프로토콜을 두지 않는다.
- Feature UseCase (`ReadingLibraryUseCase`, `DailyReadingUseCase` 등)만 Presentation 경계 프로토콜을 구현한다.

- Infrastructure protocol seam for UseCase notification side effects:

    protocol ReadingNotificationScheduling {
        func setupAllNotifications(_ readingBook: FGUserBook) async
        func clearRequests() async
    }

- Compatibility facade (production call path retired, preview/test adapters only):

    protocol BookManagementService
    final class DefaultBookManagementService

Revision Note (2026-02-12): Initial plan created to capture architecture design phase outcomes and define implementation milestones for the MV -> layered MVVM refactor.
Revision Note (2026-02-12): Added ADR linkage and explicit MVVM-vs-MVI decision rationale for presentation architecture selection.
Revision Note (2026-02-12): Updated with implementation progress (composition root + command-path migration), simulator destination discovery, and latest validation command/result.
Revision Note (2026-02-12): Completed registration/completion/date-edit command-path migration, removed presentation-side legacy calculator/modelContext writes, added new service commands/tests, and revalidated full test suite.
Revision Note (2026-02-12): Migrated `MainHomeView` query state to `MainHomeViewModel`, decoupled major route payloads to `FGUserBook`, and recorded notification-layer decoupling as the next remaining boundary task.
Revision Note (2026-02-12): Removed duplicate refactoring design memo (`docs/architecture-refactoring.md`) and consolidated canonical records into `ARCHITECTURE.md`, ADR, and this ExecPlan.
Revision Note (2026-02-12): Re-ran full test suite after latest payload/type migration and confirmed `** TEST SUCCEEDED **`.
Revision Note (2026-02-12): Completed notification-flow decoupling to `FGUserBook` (`NotiSettingView`, `NotificationManager`, `NotificationType`) and revalidated the full test suite with `** TEST SUCCEEDED **`.
Revision Note (2026-02-13): Added Phase 2 scope (feature ViewModel extraction + notification setting orchestration + ViewModel tests), recorded clean post-merge baseline verification on `develop`, and aligned acceptance criteria with remaining refactoring risk.
Revision Note (2026-02-13): Implemented Phase 2 extraction for action-heavy screens and notification settings, introduced notification abstraction seams for testability, added `PresentationViewModelTests`, and verified full suite success on iPhone 17 simulator.
Revision Note (2026-02-13): Completed the next incremental architecture step by moving Home notification setup from `MainHomeView` to `MainHomeViewModel`, extending `AppDependencies` with `NotificationManaging`, adding Home ViewModel tests, and revalidating full suite success.
Revision Note (2026-02-13): Standardized constructor injection for book-management feature ViewModels, removed `configure` call sites in Views, moved ViewModel assembly to navigation/page construction points, resolved `@MainActor` isolation by annotating `NavigationCoordinator`, and revalidated full suite success.
Revision Note (2026-02-12): Added the next architecture step for book-registration search flow by introducing `BookSearching` protocol injection in `BookSearchViewModel`, wiring it through `AppDependencies`/`BookSettingsManagerView`, adding `BookSearchViewModel` tests, and revalidating full suite success.
Revision Note (2026-02-14): Added a folder-boundary reclassification step to separate domain calculation/value types from platform and store concerns, and documented the filesystem-synchronized project behavior observed during file moves.
Revision Note (2026-02-14): Added a service-to-usecase execution split step, implemented `Domain/UseCase/BookManagement` executors, converted `DefaultBookManagementService` into a delegation facade, and validated parity via `DefaultBookManagementServiceTests`.
Revision Note (2026-02-14): Completed legacy calculator removal by replacing all `ReadingDateCalculator`/`ReadingPagesCalculator` usage with `DateMathCalculator`/`PageMathCalculator`, deleted deprecated util files, delegated SwiftData reading helper methods to domain model APIs, and created `docs/execplans/tech-debt-tracker.md` for remaining day-boundary/domain-cleanup debt.
Revision Note (2026-02-14): Added Phase 3 architecture design for UseCase-first boundary (`ViewModel -> UseCase`), synchronized plan acceptance criteria/interfaces, and linked ADR-0002 for service terminology and migration policy.
Revision Note (2026-02-14): Began Phase 3 implementation with UseCase protocol boundary introduction and MainHome vertical-slice migration to direct UseCase injection from composition root, keeping service-based compatibility initializer during transition.
Revision Note (2026-02-14): Reduced MainHome over-splitting by introducing feature-composed `ReadingLibraryUseCase`/`ReadingLibraryUsing`, updated composition-root and ViewModel wiring to a single dependency boundary, and revalidated focused regression tests to preserve behavior parity.
Revision Note (2026-02-14): Updated MainHome composite use case to sequential home-list fetching after reviewing shared `ModelContext` safety risk in repository implementation, then reran focused regression tests with success.
Revision Note (2026-02-14): Applied domain-focused naming to the composite home/library use case boundary (`ReadingLibrary*`) and synchronized AppDependencies/MainHomeViewModel property labels, then reran focused regression tests.
Revision Note (2026-02-14): Completed Phase 3 production migration by moving all target ViewModels to direct UseCase dependencies, introducing `ReadingNotificationScheduling` for UseCase infra decoupling, and synchronizing architecture docs/ADR/ExecPlan to the finalized boundary (`ViewModel -> UseCase -> Repository/Infrastructure Service`).
Revision Note (2026-02-14): Resolved TD-001 by introducing `DayBoundaryProviding` policy centralization, migrated adjusted-date/day-key call sites to `DayBoundary.shared`, added `DayBoundaryPolicyTests`, and revalidated full regression with `** TEST SUCCEEDED **`.
Revision Note (2026-02-14): Reduced UseCase over-splitting by removing transitional action-level `...Using` protocols, kept feature-level boundary protocols for ViewModel injection, and updated interfaces documentation to match the implemented structure.
Revision Note (2026-02-14): Migrated `DefaultBookManagementServiceTests` to `BookManagementUseCasesTests` so regression coverage aligns with the current UseCase-first execution boundary and no longer centers on the compatibility facade.
