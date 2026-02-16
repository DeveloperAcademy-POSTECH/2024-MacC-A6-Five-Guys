# TD-007 Reading Date Key Hardening

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`PLANS.md` exists at repository root. This plan is maintained in accordance with `PLANS.md`.

## Purpose / Big Picture

After this change, date keys used for reading records will be generated with an explicit app timezone (`Calendar.app.timeZone`) and passed through a domain value type instead of raw `String` in key comparison logic. This prevents environment-dependent key mismatches and reduces accidental mixing of "date value" and "reading record key" semantics.

User-visible behavior should remain unchanged. The observable outcome is that existing reading schedule and notification tests continue to pass, while new tests prove timezone-explicit key generation and typed key ordering/parsing.

## Progress

- [x] (2026-02-14 17:40Z) Scoped TD-007 impact by auditing all `toYearMonthDayString`/`toDate` usages and DayBoundary/date-key call paths.
- [x] (2026-02-14 17:42Z) Added `ReadingDateKey` value object at `Sources/Domain/Entity/ReadingDateKey.swift` with explicit timezone formatter/parser and `Comparable`.
- [x] (2026-02-14 17:43Z) Routed date-key generation/parsing through `ReadingDateKey` in `Date+Extension` and `String+Extension`.
- [x] (2026-02-14 17:43Z) Applied typed-key usage in domain core paths (`ReadingScheduleCalculator`, `FGUserBook`, `FGReadingProgress+Notification`, SwiftData `ReadingProgress` key helper, `DayBoundaryProviding`).
- [x] (2026-02-14 17:44Z) Added policy tests for typed date key behavior (`ReadingDateKeyTests`) and aligned `DayBoundaryPolicyTests` to typed return value.
- [x] (2026-02-14 17:45Z) Ran focused regression suites (`DayBoundaryPolicyTests`, `ReadingDateKeyTests`, `FGReadingProgressNotificationTests`, `ReadingScheduleCalculator*`, `BookManagementUseCases*`) with `** TEST SUCCEEDED **`.
- [x] (2026-02-15 03:00Z) Finalized release decision: skip automatic storage-key migration and keep the current Korea-fixed policy; document global timezone UX as follow-up tech debt.
- [x] (2026-02-15 06:40Z) Added one-time compatibility migration in `SwiftDataBookRepository` to normalize legacy reading-record keys using `ReadingDateKey` policy.

## Surprises & Discoveries

- Observation: `toYearMonthDayString()` and `String.toDate()` currently create `DateFormatter` without explicit timezone, while app calendar is fixed to `Asia/Seoul`.
  Evidence: `FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`, `FiveGuyes/FiveGuyes/Resources/Extensions/String+Extension.swift`.

- Observation: Date-key ordering logic currently relies on raw `String` comparisons in schedule and notification flows.
  Evidence: `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/Entity/Extension/FGReadingProgress+Notification.swift`.

- Observation: SwiftData persistence key type migration was unnecessary to achieve policy safety; typed boundaries can be introduced while preserving `[String: ReadingRecord]` storage.
  Evidence: `ReadingDateKey` introduced without changing model schema and all focused regression suites passed.

## Decision Log

- Decision: Keep persisted dictionary shape as `[String: ReadingRecord]` for this scope and introduce typed wrapper at generation/comparison boundaries.
  Rationale: Changing persistence key type would expand into migration scope and exceed TD-007 minimal-risk objective.
  Date/Author: 2026-02-14 / Codex

- Decision: Change `DayBoundaryProviding.adjustedDayKey(from:)` to return `ReadingDateKey` and convert to `String` only at legacy boundaries.
  Rationale: This improves type safety where policy key is produced while keeping existing APIs compatible with stored record dictionaries.
  Date/Author: 2026-02-14 / Codex

- Decision: Introduce one-time runtime compatibility migration for previously stored reading-record keys.
  Rationale: After `ReadingDateKey` policy hardening, legacy keys remained the main source of runtime mismatch risk. One-time write-back at repository fetch boundary removes repeated fallback branching and aligns persisted data to current policy.
  Date/Author: 2026-02-15 / Codex

## Outcomes & Retrospective

TD-007 core objective was achieved without schema version migration. Date-key generation/parsing now goes through `ReadingDateKey`, which forces `Calendar.app.timeZone` and centralizes `yyyy-MM-dd` normalization rules. Day boundary key production now returns typed keys, and domain key-comparison paths in schedule/notification/entity helpers no longer rely on ad-hoc string generation at call sites.

Additionally, this cycle introduced a one-time repository-level compatibility migration for legacy stored keys. The migration keeps persisted shape as `[String: ReadingRecord]` while normalizing/merging keys to the current policy. Residual debt remains for global timezone UX expansion and long-term policy transition strategy.

## Context and Orientation

Reading record keys are currently plain `String` (`yyyy-MM-dd`) across domain and data models. In this repository, "reading date key" means the normalized key string used as dictionary key for `FGReadingProgress.dailyReadingRecords` and SwiftData `ReadingProgress.readingRecords`.

Key files involved:

- Key format and conversion helpers:
  - `FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`
  - `FiveGuyes/FiveGuyes/Resources/Extensions/String+Extension.swift`
- Day boundary policy:
  - `FiveGuyes/FiveGuyes/Sources/Domain/Service/DayBoundaryProviding.swift`
- Core key consumers:
  - `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/Entity/Extension/FGReadingProgress+Notification.swift`
  - `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`

The target architecture for this task is: key semantics are represented by a domain type (`ReadingDateKey`), key generation and parsing are timezone-explicit, and raw string handling is minimized.

## Plan of Work

First, add a domain value object `ReadingDateKey` that owns `yyyy-MM-dd` formatting/parsing with `Calendar.app.timeZone`. The type provides ordering (`Comparable`) and conversion from/to `Date`.

Second, make Date/String extensions delegate key conversion to this type so legacy call sites keep compiling while behavior becomes timezone-explicit and centralized.

Third, migrate core domain comparison points away from ad-hoc string comparison to typed key comparison. This includes schedule calculation branches, notification next-day search, and domain entity key lookup helpers.

Fourth, update policy and tests: DayBoundary returns typed keys, and tests verify key generation/parsing and boundary consistency.

## Concrete Steps

From repository root (`/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`):

1. Add `FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift`.
2. Update:
   - `FiveGuyes/FiveGuyes/Sources/Domain/Service/DayBoundaryProviding.swift`
   - `FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`
   - `FiveGuyes/FiveGuyes/Resources/Extensions/String+Extension.swift`
3. Update typed-key consumption in:
   - `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
   - `FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift`
   - `FiveGuyes/FiveGuyes/Sources/Domain/Entity/Extension/FGReadingProgress+Notification.swift`
4. Add/adjust tests:
   - `FiveGuyes/FiveGuyesTests/Domain/Policy/ReadingDateKeyTests.swift` (new)
   - `FiveGuyes/FiveGuyesTests/Domain/Policy/DayBoundaryPolicyTests.swift` (update if needed)
5. Run focused regression commands:
   - `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/DayBoundaryPolicyTests`
   - `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/FGReadingProgressNotificationTests`
   - `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/ReadingScheduleCalculatorRescheduleTests`

## Validation and Acceptance

Acceptance criteria:

1. `toYearMonthDayString()` and `String.toDate()` are timezone-explicit via centralized key type.
2. Core domain key comparison code uses `ReadingDateKey` instead of ad-hoc raw string comparisons.
3. Day-boundary key path remains behavior-compatible at 03:59/04:00.
4. Focused domain tests pass:
   - DayBoundary policy tests
   - Notification key/date tests
   - Reading schedule reschedule tests

## Idempotence and Recovery

Changes are additive and idempotent. If a step fails, rerun tests after fixing compile errors; no schema/destructive migration command is included. Repository-level compatibility migration is one-time and guarded by a completion flag. If typed-key migration causes unexpected regressions, rollback can be done file-by-file to previous string comparison logic without data loss because persisted storage shape remains unchanged.

## Artifacts and Notes

Executed validation commands (all succeeded):

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/ReadingDateKeyTests -only-testing:FiveGuyesTests/DayBoundaryPolicyTests -only-testing:FiveGuyesTests/FGReadingProgressNotificationTests -only-testing:FiveGuyesTests/ReadingScheduleCalculatorApplyTodayReadingTests -only-testing:FiveGuyesTests/ReadingScheduleCalculatorRescheduleTests

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/ReadingScheduleCalculatorInitialScheduleTests -only-testing:FiveGuyesTests/ReadingScheduleCalculatorApplyTodayReadingTests -only-testing:FiveGuyesTests/ReadingScheduleCalculatorRescheduleTests

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/BookManagementUseCasesQueryAndRegistrationTests -only-testing:FiveGuyesTests/BookManagementUseCasesDailyReadingTests -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests

## Interfaces and Dependencies

Target interfaces:

- `struct ReadingDateKey` with:
  - `init(date: Date, calendar: Calendar = .app)`
  - `init?(parsing rawValue: String, calendar: Calendar = .app)`
  - `var rawValue: String`
  - `func toDate(calendar: Calendar = .app) -> Date?`
  - `Comparable` conformance by normalized key string

- `protocol DayBoundaryProviding`:
  - `func adjustedDayKey(from date: Date) -> ReadingDateKey`

No new external libraries are required; use `Foundation`, existing `Calendar.app`, and existing domain modules only.

---

Plan revision note (2026-02-14): created initial TD-007 execution plan to convert date-key handling from implicit formatter/string logic to timezone-explicit typed key boundaries.
Plan revision note (2026-02-14): completed implementation and validation; updated progress/outcomes/artifacts with concrete results.
Plan revision note (2026-02-15): fixed release scope to "no automatic migration", aligned with current Korea-fixed policy, and moved global timezone UX to tech debt follow-up.
Plan revision note (2026-02-15): added one-time compatibility migration in repository layer and updated rationale/outcomes accordingly.
