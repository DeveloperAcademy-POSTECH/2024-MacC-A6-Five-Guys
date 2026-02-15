# Reading Record Key Migration Lightweight Refactor

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`PLANS.md` exists at repository root. This plan is maintained in accordance with `PLANS.md`.

## Purpose / Big Picture

이 작업의 목적은 "기능을 바꾸지 않고 구조를 단순화"하는 것입니다. 사용자에게 보이는 동작은 기존과 동일하게 유지하면서, 마이그레이션 관련 책임을 repository 내부로 국소화해 코드 이해/삭제를 쉽게 만듭니다.

완료 후에는 다음이 가능해야 합니다.

- 상용 앱 경로는 기존처럼 `SwiftDataBookRepository(modelContainer:)`만 사용한다.
- 테스트는 독립 `UserDefaults`를 주입해 마이그레이션 플래그를 격리 검증한다.
- 마이그레이션 제거 시 repository 내부 코드만 삭제하면 된다.

## Progress

- [x] (2026-02-15 11:20Z) 마이그레이션 시작 계기와 정책(legacy key mismatch, 04:00 경계, one-time write-back) 재정리.
- [x] (2026-02-15 11:25Z) `SwiftDataBookRepository` 상태 저장 추상화 제거 및 `UserDefaults` 직접 사용 구조 반영.
- [x] (2026-02-15 11:30Z) repository 내부 `ReadingRecordKeyMigrationV1` 캡슐화 반영.
- [x] (2026-02-15 11:34Z) `ReadingDateKey.shifted(by:)` 제거 및 도메인 fallback(`fromStoredKey`) 유지.
- [x] (2026-02-15 11:40Z) repository/도메인 테스트 시나리오를 새 구조로 동기화.
- [x] (2026-02-15 11:45Z) ADR/tech-debt/architecture 문서 동기화 계획 반영.
- [x] (2026-02-15 11:24Z) focused/flaky/full 회귀 테스트 실행 및 결과 기록.
- [x] (2026-02-16 01:10Z) 부수효과 완화를 위해 app-start prewarm + 앱 스코프 completion key + legacy fallback 승격 전략 확정/반영.

## Surprises & Discoveries

- Observation: 현재 키 변환 규칙은 "기본값 0 이동 + 근거 충분 시에만 ±1 이동"이 안전성/보수성 균형점이었다.
  Evidence: `lastReadDate` anchor 기반 추론에서 `abs(diff) > 1`일 때 no-op을 유지해야 대량 오이동을 방지할 수 있었다.

- Observation: 상용 경로 안정성과 테스트 격리를 동시에 만족시키려면 생성자 2단 구조가 필요했다.
  Evidence: `init(modelContainer:)` 유지 + 주입 생성자(`migrationUserDefaults`, `migrationCompletionKey`) 분리로 기존 앱 호출부 변경 없이 테스트 독립성 유지 가능.

- Observation: 마이그레이션 전용 동작(`shifted`)은 도메인 타입보다 repository 내부 정책 구현에 더 적합했다.
  Evidence: `ReadingDateKey`는 공통 fallback 경로(`fromStoredKey`)만 유지해도 스케줄/알림 비교 요구를 충족했다.

## Decision Log

- Decision: 저장 스키마(`[String: ReadingRecord]`)는 유지하고 repository 경계에서만 1회 호환 보정을 수행한다.
  Rationale: 스키마 변경 리스크 없이 런타임 불일치 문제를 해소할 수 있다.
  Date/Author: 2026-02-15 / FiveGuyes team

- Decision: 마이그레이션 상태 저장 추상화 타입을 제거한다.
  Rationale: 실사용 경로가 repository 단일 경계로 수렴했기 때문에 추상화 유지 비용이 이득보다 컸다.
  Date/Author: 2026-02-15 / FiveGuyes team

- Decision: 기본 생성자는 유지하고 주입 생성자를 테스트용으로 분리한다.
  Rationale: 상용 호출 안정성과 테스트 격리 주입을 동시에 만족하기 위함.
  Date/Author: 2026-02-15 / FiveGuyes team

- Decision: 마이그레이션 알고리즘은 repository 내부 구조체(`ReadingRecordKeyMigrationV1`)로 캡슐화한다.
  Rationale: 향후 삭제 비용을 줄이고 변경 범위를 repository 내부로 고정하기 위함.
  Date/Author: 2026-02-15 / FiveGuyes team

- Decision: 완료 플래그는 앱/스토어/버전 스코프 키로 전환하고, 기존 단일 키는 fallback read 후 승격한다.
  Rationale: 전역 단일 키 충돌 가능성을 줄이면서 사용자 재마이그레이션 비용을 최소화하기 위함.
  Date/Author: 2026-02-16 / FiveGuyes team

- Decision: 마이그레이션을 앱 시작 시 prewarm으로 선실행하고 fetch 경계 호출은 fallback으로 유지한다.
  Rationale: 첫 조회 시 write 부작용을 완화하면서 안전한 재시도 경계를 유지하기 위함.
  Date/Author: 2026-02-16 / FiveGuyes team

## Outcomes & Retrospective

이번 리팩토링으로 정책은 유지되고 구현 복잡도는 줄어들었다. 특히 "왜 이 마이그레이션이 존재하는지"와 "언제/어떻게 제거할 수 있는지"가 문서와 코드 경계에 동시에 반영되었다.

남은 과제는 두 가지다.

1. 글로벌 타임존 UX 확장 시 버전드 마이그레이션 전략 재설계.
2. 외부 import/백업 복원 등 legacy key 재유입 경로가 생길 때 completion flag 정책 보강.

## Context and Orientation

핵심 파일:

- `FiveGuyes/FiveGuyes/Sources/Data/RepositoryImpl/SwiftDataBookRepository.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift`
- `FiveGuyes/FiveGuyesTests/Data/Repository/SwiftDataBookRepositoryTests.swift`
- `FiveGuyes/FiveGuyesTests/Domain/Policy/ReadingDateKeyTests.swift`
- `docs/decisions/adr-0003-reading-record-key-migration-policy.md`
- `docs/execplans/tech-debt-tracker.md`

아키텍처 관점에서 이 변경은 `Data` 계층 내부 정리이며, `Domain` 공개 의미(날짜 키 fallback)와 `Presentation` 경계는 변경하지 않는다.

## Plan of Work

먼저 repository에서 상태 저장 추상화를 제거하고 `UserDefaults` 직접 접근으로 단순화한다. 다음으로 마이그레이션 로직을 내부 구조체로 옮겨 책임을 캡슐화한다. 이어서 `ReadingDateKey`에서 마이그레이션 전용 API를 제거해 도메인 순도를 유지한다. 마지막으로 테스트와 문서를 새 구조에 맞춰 동기화한다.

## Concrete Steps

작업 디렉터리:

`/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

정적 검증:

    rg "ReadingRecordKeyMigrationStateStoring|UserDefaultsReadingRecordKeyMigrationStateStore" FiveGuyes/FiveGuyes/Sources FiveGuyes/FiveGuyesTests
    rg "func shifted\\(by" FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift

핵심 테스트:

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/SwiftDataBookRepositoryTests -only-testing:FiveGuyesTests/ReadingDateKeyTests -only-testing:FiveGuyesTests/FGReadingProgressNotificationTests -only-testing:FiveGuyesTests/ReadingScheduleCalculatorRescheduleTests

플래키 회귀:

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -test-iterations 5 -only-testing:FiveGuyesTests/DailyProgressViewModelTests -only-testing:FiveGuyesTests/CompletionReviewViewModelTests -only-testing:FiveGuyesTests/ReadingDateEditViewModelTests

전체 회귀:

    xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17"

## Validation and Acceptance

- 상태 저장 추상화 타입 검색 결과가 0건이다.
- `ReadingDateKey.shifted(by:)` 검색 결과가 0건이다.
- 기존 마이그레이션 시나리오 테스트가 통과한다.
- 보강 시나리오(guard-range/no-op, 정규화, no-mutation completion flag) 테스트가 통과한다.
- ADR/execplan/architecture 문서가 최신 구현 구조를 설명한다.

## Idempotence and Recovery

이번 변경은 스키마 마이그레이션이 아니며, 코드/문서 정리 중심이다. 실패 시 파일 단위로 재시도 가능하며 데이터 스토어를 파괴하지 않는다. 마이그레이션 실패 시 completion flag를 기록하지 않는 정책을 유지해 다음 fetch에서 재시도 가능하다.

## Artifacts and Notes

- Focused tests: `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:FiveGuyesTests/SwiftDataBookRepositoryTests -only-testing:FiveGuyesTests/ReadingDateKeyTests -only-testing:FiveGuyesTests/FGReadingProgressNotificationTests -only-testing:FiveGuyesTests/ReadingScheduleCalculatorRescheduleTests`
  - Result: `TEST SUCCEEDED` (2026-02-15 20:21 KST)
  - xcresult: `/Users/zaehorang/Library/Developer/Xcode/DerivedData/FiveGuyes-bznqavdsjsxffbaoiasvqswdmngq/Logs/Test/Test-FiveGuyes-2026.02.15_20-21-04-+0900.xcresult`
- Flaky regression (5 iterations): `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17" -test-iterations 5 -only-testing:FiveGuyesTests/DailyProgressViewModelTests -only-testing:FiveGuyesTests/CompletionReviewViewModelTests -only-testing:FiveGuyesTests/ReadingDateEditViewModelTests`
  - Result: `TEST SUCCEEDED` (2026-02-15 20:22 KST)
  - xcresult: `/Users/zaehorang/Library/Developer/Xcode/DerivedData/FiveGuyes-bznqavdsjsxffbaoiasvqswdmngq/Logs/Test/Test-FiveGuyes-2026.02.15_20-22-12-+0900.xcresult`
- Full regression: `xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "platform=iOS Simulator,name=iPhone 17"`
  - Result: `TEST SUCCEEDED` (2026-02-15 20:23 KST)
  - xcresult: `/Users/zaehorang/Library/Developer/Xcode/DerivedData/FiveGuyes-bznqavdsjsxffbaoiasvqswdmngq/Logs/Test/Test-FiveGuyes-2026.02.15_20-23-09-+0900.xcresult`

## Interfaces and Dependencies

- Repository API:
  - `convenience init(modelContainer:)` (상용 경로)
  - `init(modelContainer:migrationUserDefaults:migrationCompletionKey:)` (테스트 주입 경로)
- Domain API:
  - `ReadingDateKey.fromStoredKey(_:)` 유지
  - `ReadingDateKey.shifted(by:)` 제거
- 외부 라이브러리 추가 없음 (`Foundation`, `SwiftData`만 사용)

Plan revision note (2026-02-15): 생성자 전략(상용 유지 + 테스트 주입), day shift 기본값 정책(0 우선), 문서화 범위(ADR+ExecPlan+TechDebt+Architecture)를 확정 반영.
