# Source Tree Normalization for Layer-First Architecture

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

FiveGuyes already follows a layer-first architecture (`App/Presentation/Domain/Data/Platform`), but the current source tree still has inconsistent naming (`Noti` vs `Notification`), empty folders, and file/object mismatches (`BookLowView.swift` containing `BookRowView`). These inconsistencies slow down onboarding and increase review friction because contributors cannot reliably infer intent from paths and names.

After this change, contributors should be able to open the source tree and immediately understand where to put new code and how to name files/types. This work is intentionally behavior-preserving: no business rule changes, only source organization and naming normalization.

## Progress

- [x] (2026-02-15 17:58Z) Baseline inspection complete (branch, source tree shape, empty folders, naming mismatches).
- [x] (2026-02-15 17:58Z) Confirmed project uses file-system-synced groups (`PBXFileSystemSynchronizedRootGroup`), so path moves are low-risk for project references.
- [x] (2026-02-15 18:02Z) Applied structural hygiene moves: extensions moved out of `Resources`, calculator files moved out of `Sources/Util`, and typography source files moved into `Sources/Presentation/Shared/Typography`.
- [x] (2026-02-15 18:03Z) Normalized notification naming (`Noti*` -> `NotificationSettings*`) across view, view model, tests, and route case (`notificationSettings`).
- [x] (2026-02-15 18:04Z) Resolved file/object mismatch (`BookLowView.swift` -> `BookRowView.swift`) and removed empty architecture drift folders (`Sources/Protocol`, `Sources/Domain/UseCase/Common`, `Sources/Util`).
- [x] (2026-02-15 18:07Z) Executed full simulator test run for `FiveGuyes` scheme on iOS 26.2 and confirmed `** TEST SUCCEEDED **`.
- [x] (2026-02-15 18:08Z) Updated ADR/tech-debt documentation paths and renamed type references.

## Surprises & Discoveries

- Observation: The Xcode project does not enumerate each source file in `PBXSourcesBuildPhase`; it uses file-system synchronized groups.
  Evidence: `FiveGuyes/FiveGuyes.xcodeproj/project.pbxproj` contains `PBXFileSystemSynchronizedRootGroup` and empty `files = ()` in source build phases.

- Observation: `feature/td-014-book-search-boundary-alignment` already moved the book-search implementation from legacy `Store/` paths to `Platform/BookSearch`.
  Evidence: `FiveGuyes/FiveGuyes/Sources/Platform/BookSearch/AladinBookSearchProvider.swift` and `.../Model/AladinBookSearchDTO.swift` exist; `Sources/Store` does not exist.

- Observation: Test execution fails on iOS 18.x simulators because the unit-test target deployment target is iOS 26.0.
  Evidence: `xcodebuild test ... -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'` failed with deployment-target mismatch; rerun on iOS 26.2 succeeded.

## Decision Log

- Decision: Keep layer-first topology and avoid feature-first full migration in this plan.
  Rationale: Current ADRs and architecture docs are already aligned to layer-first boundaries; full feature-first migration is broader than requested scope and riskier.
  Date/Author: 2026-02-15 / Codex

- Decision: Treat this refactor as behavior-preserving and reject logic changes unless required to compile.
  Rationale: User request is structure and consistency, not feature behavior.
  Date/Author: 2026-02-15 / Codex

- Decision: Execute in two technical passes: (1) filesystem/naming cleanup, (2) compile/test verification and documentation sync.
  Rationale: Keeps rollback and debugging straightforward if any path rename breaks compilation.
  Date/Author: 2026-02-15 / Codex

## Outcomes & Retrospective

The refactor finished as a behavior-preserving source-tree normalization pass. Layer boundaries stayed intact while naming and filesystem hygiene were improved. `Noti` naming was fully eliminated from active source/tests, source code was removed from `Resources/Extensions`, and empty drift directories were deleted.

The build/test outcome confirms no functional regression under the target simulator runtime (`iOS 26.2`): full test suite passed with `** TEST SUCCEEDED **`. Remaining naming debt is limited to intentional multi-type files (for example, bundled UseCase files), which were not split in this pass to keep scope focused.

## Context and Orientation

The current source root is `FiveGuyes/FiveGuyes/Sources`. Major stable layer directories are already present:

- `App`: app bootstrap and dependency composition.
- `Presentation`: views, view models, and UI components.
- `Domain`: entities, use cases, repositories, services, calculators.
- `Data`: persistence implementations and SwiftData models.
- `Platform`: external/system integrations (notification, analytics, book search provider).

Current inconsistencies this plan addresses:

- Empty directories:
  - `FiveGuyes/FiveGuyes/Sources/Protocol`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Common`
- Inconsistent notification naming:
  - `FiveGuyes/FiveGuyes/Sources/Presentation/View/NotiSetting/NotiSettingView.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotiSettingViewModel.swift`
  - `Screens.notiSetting` route in `NavigationCoordinator`
- File/object mismatch:
  - `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookLowView.swift` defines `BookRowView`.
- Utility placement drift:
  - `FiveGuyes/FiveGuyes/Sources/Util/*.swift` contains core calculators (`DateMathCalculator`, `PageMathCalculator`) used by domain logic.
- Source-code extensions under resources:
  - `FiveGuyes/FiveGuyes/Resources/Extensions/*.swift` are source code, not static assets.

## Plan of Work

First, normalize filesystem paths and names while preserving symbols where possible. Move calculator files into `Domain/Calculator` and migrate code extensions into source-layer extension folders so resource directories contain assets only.

Second, standardize notification naming by renaming `NotiSettingView`/`NotiSettingViewModel` and their route case to `NotificationSettings...` names across source and tests.

Third, resolve file/object mismatches (`BookLowView.swift` -> `BookRowView.swift`), remove empty folders, and fix any file header/path comments touched by rename.

Finally, run build/tests and update architecture/debt docs to record the new canonical structure and naming choices.

## Concrete Steps

From repo root `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`:

1. Move and rename files/directories with `git mv`:
   - `Presentation/View/NotiSetting` -> `Presentation/View/NotificationSettings`
   - `NotiSettingView.swift` -> `NotificationSettingView.swift`
   - `NotiSettingViewModel.swift` -> `NotificationSettingViewModel.swift`
   - `NotiSettingViewModelTests.swift` -> `NotificationSettingViewModelTests.swift`
   - `BookLowView.swift` -> `BookRowView.swift`
   - `Sources/Util/DateMathCalculator.swift` -> `Sources/Domain/Calculator/DateMathCalculator.swift`
   - `Sources/Util/PageMathCalculator.swift` -> `Sources/Domain/Calculator/PageMathCalculator.swift`
   - `Sources/Util/CalendarCalculator.swift` -> `Sources/Presentation/Shared/Calendar/CalendarCalculator.swift`
   - `Resources/Extensions/*` -> source extension folders under `Sources`

2. Update symbol and route names with targeted replacements:
   - `NotiSettingView` -> `NotificationSettingView`
   - `NotiSettingViewModel` -> `NotificationSettingViewModel`
   - route case `notiSetting` -> `notificationSettings`

3. Remove empty directories:
   - `Sources/Protocol`
   - `Sources/Domain/UseCase/Common`
   - any now-empty folders produced by moves

4. Validate:
   - `xcodebuild -list -project FiveGuyes/FiveGuyes.xcodeproj`
   - `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'`

5. Update architecture/debt docs to match final paths and naming.

## Validation and Acceptance

Acceptance is satisfied when all of the following are true:

- Build/test command succeeds for `FiveGuyes` scheme.
- `rg -n "NotiSetting|notiSetting"` in `Sources` and `FiveGuyesTests` returns no active symbol usage.
- `find FiveGuyes/FiveGuyes/Sources -type d -empty` returns no architecture drift directories (`Protocol`, `UseCase/Common`, etc.).
- `find FiveGuyes/FiveGuyes/Resources -name '*.swift'` returns no source files (only resources remain in resources tree).
- App navigation to notification settings still compiles and route wiring remains intact.

## Idempotence and Recovery

Most operations are path renames and are idempotent if repeated with existence checks. If a step fails mid-way:

- Re-run `git status` to identify partial rename state.
- Complete the missing `git mv` operations.
- Re-run symbol replacement checks (`rg`) before test/build.

Rollback can be done per-file with `git restore --staged <path>` and `git restore <path>` if needed.

## Artifacts and Notes

Validation snippets:

    $ git status -sb
    ## feature/source-structure-normalization

    $ rg -n "NotiSetting|notiSetting" FiveGuyes/FiveGuyes/Sources FiveGuyes/FiveGuyesTests
    (no matches)

    $ find FiveGuyes/FiveGuyes/Resources -name '*.swift'
    (no output)

    $ xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
    ** TEST SUCCEEDED **

## Interfaces and Dependencies

Public behavior does not change. Interface-level changes are naming-only:

- `NotiSettingView` -> `NotificationSettingView`
- `NotiSettingViewModel` -> `NotificationSettingViewModel`
- `Screens.notiSetting(book:)` -> `Screens.notificationSetting(book:)`

These names are consumed only inside app code and tests in this repository. No external API/schema/dependency changes are introduced.

Revision Note (2026-02-15): Updated this ExecPlan from design-only state to implementation-complete state by recording executed file moves/renames, simulator test evidence, and documentation synchronization details so future contributors can audit exactly what changed and why.
