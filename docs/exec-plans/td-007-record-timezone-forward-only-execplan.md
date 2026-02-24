# TD-007 Record TimeZone Snapshot and Forward-Only Policy

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/PLANS.md`.

## Purpose / Big Picture

사용자가 해외로 이동해도 과거 독서 기록은 당시 날짜 경험을 유지하고, 이후 새로 생성/재계산되는 기록만 현재 기기 타임존 기준으로 저장하도록 TD-007 후속을 마무리한다. 사용자는 키 포맷 변경이나 기존 데이터 손상 없이 글로벌 이동 시나리오를 경험할 수 있어야 한다.

이 변경 후 검증 가능한 결과는 다음이다. `readingRecords`의 key는 여전히 `yyyy-MM-dd`이고, 각 `ReadingRecord` 값에 `timeZoneID`가 저장된다. 해외 이동 시 과거 key는 유지되고, 이후 기록만 새 타임존으로 스탬프된다.

## Progress

- [x] (2026-02-17 14:05Z) 후보안/선택 근거 정리를 위한 문서 전략을 `ExecPlan + ADR`로 확정.
- [x] (2026-02-17 14:10Z) `ReadingRecord`에 `timeZoneID`와 legacy 디코딩 fallback(`Asia/Seoul`) 적용.
- [x] (2026-02-17 14:14Z) `ReadingScheduleCalculator` write 경로에 `activeTimeZoneID` 전달 경계 추가.
- [x] (2026-02-17 14:18Z) `DailyAndPlanUseCases`, `LibraryAndRegistrationUseCases`, `AppDependencies`에 `ReadingTimeZoneProviding` 주입 연결.
- [x] (2026-02-17 14:21Z) `toAdjustedYearMonthDayString` 제거 및 `DayBoundaryPolicyTests` 정책 경로 정리.
- [x] (2026-02-17 14:24Z) TimeZone 관련 신규 테스트(`ReadingRecordTimeZoneTests`, UseCase 시나리오 보강) 추가.
- [x] (2026-02-17 14:32Z) `tech-debt-tracker.md`, `architecture-debt-issue-plans.md`, `ADR-0004` 문서 동기화.
- [x] (2026-02-17 14:37Z) focused regression 테스트 실행(`ReadingRecordTimeZoneTests`, `DayBoundaryPolicyTests`, `ReadingScheduleCalculatorInitial/ApplyTodayReadingTests`, BookManagement/SwiftData 관련 대상) 및 통과 확인.
- [x] (2026-02-17 15:31Z) 후속 회귀 테스트 실행: `ReadingDateKeyTests`, `DayBoundaryPolicyTests`, `BookManagementUseCasesDailyReadingTests`, `BookManagementUseCasesCompletionAndPlanTests`, `UnfinishReadingViewModelTests`, `ReadingRecordTimeZoneTests`, `SwiftDataBookRepoTests` 통과.
- [x] (2026-02-17 18:20Z) F1 후속 적용: `Calendar.app` 타임존을 현재 기기 기준으로 전환하고 관련 정책/테스트 문서를 동기화.
- [x] (2026-02-17 18:30Z) F4/F5 후속 적용: `ReadingRecord` 타임존 정규화/병합 공용 정책 함수로 중복 제거 + 정책/Repo 스모크 테스트 보강.

## Surprises & Discoveries

- Observation: 기존 `ReadingRecord`는 `ReadingProgress` 내부 값 타입(Codable)으로 저장되어 SwiftData 스키마 버전업 없이 호환 확장이 가능했다.
  Evidence: `Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`의 `[String: ReadingRecord]` 구조.

- Observation: `toAdjustedYearMonthDayString`는 운영 코드에서 사실상 사용되지 않고 테스트 1건만 의존하고 있었다.
  Evidence: 전역 검색 결과와 `DayBoundaryPolicyTests` 경로.

- Observation: TD-007 대상 테스트 실행 시 기능 실패는 없었고, 기존 SwiftLint 길이 경고만 출력되었다.
  Evidence: `xcodebuild test` 종료 코드 0 + 경고(`file_length`, `type_body_length`)만 출력.

## Decision Log

- Decision: 저장 key는 기존 `yyyy-MM-dd`를 유지하고 key suffix(`|timezone`)를 도입하지 않는다.
  Rationale: key 파싱/정렬/호환성 리스크를 최소화하고 기존 저장 구조를 안정적으로 유지하기 위함.
  Date/Author: 2026-02-17 / Codex

- Decision: 타임존은 `ReadingRecord.timeZoneID`에 레코드 단위로 저장한다.
  Rationale: 과거 기록 보존과 이후 기록의 현지화 요구를 동시에 만족하려면 record-level snapshot이 가장 단순하고 정확하다.
  Date/Author: 2026-02-17 / Codex

- Decision: forward-only 정책을 채택한다(과거 재버킷팅 금지).
  Rationale: 과거 key 재작성은 대규모 재해석 리스크가 크고, 운영 안전성을 저해한다.
  Date/Author: 2026-02-17 / Codex

- Decision: `Calendar.app` 전역 개편은 이번 범위에서 제외하고 write 경계 최소 분리만 수행한다.
  Rationale: TD-007 1차 목표 달성에 필요한 최소 변경으로 회귀 범위를 제어하기 위함.
  Date/Author: 2026-02-17 / Codex

- Decision: F1 후속에서 `Calendar.app` 타임존을 `.autoupdatingCurrent`로 전환해 save/read/reschedule 버킷 기준을 현지 정책으로 맞춘다.
  Rationale: record-level `timeZoneID` 저장만으로는 현지 날짜 기준 저장 UX를 충족하지 못해 런타임 버킷팅 기준 전환이 필요했다.
  Date/Author: 2026-02-17 / Codex

## Outcomes & Retrospective

TD-007 후속 범위(레코드 단위 타임존 스냅샷 + forward-only)는 계획대로 반영됐다. key 포맷은 유지되고 신규/재계산 레코드는 `timeZoneID`를 저장한다. legacy decode fallback과 migration merge/normalize 보강으로 기존 데이터 호환도 유지했다.

추가로 F1 후속에서 날짜 버킷팅 기준을 `Calendar.app(현재 기기 time zone)`으로 전환해 save/read/reschedule 경계를 일치시켰다. F4/F5 후속으로 타임존 정규화/병합 정책을 공용 함수로 단일화하고 관련 테스트 공백을 보강했다.

남은 범위는 typed key adapter 확대와 글로벌 정책 UX(사용자 설정 기반 day-boundary/timezone) 분리다. 따라서 tracker 상태는 `Partial`로 유지한다.

## Context and Orientation

현재 저장 구조는 다음 파일에서 정의된다.

- `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingRecord.swift`

`ReadingProgress`는 SwiftData `@Model`이고 `readingRecords`는 `[String: ReadingRecord]` 형태다. 즉 `ReadingRecord`는 독립 `@Model`이 아니라 값 타입이다.

TD-007 1차에서는 `ReadingDateKey`와 migration(`ADR-0003`)으로 key 정책을 고정했다. 남은 과제는 “해외 이동 시 과거/현재 기록의 타임존 의미를 어떻게 보존할 것인가”다.

## Plan of Work

먼저 결정 근거를 ADR로 고정한다. 후보안과 미선택 사유를 남기고, 이번 실행 범위(레코드 스냅샷 + forward-only)를 명확히 한다.

다음으로 코드에서 `ReadingRecord`를 확장하고, 스케줄 계산 write 경로에 `activeTimeZoneID`를 전달한다. UseCase 계층은 `ReadingTimeZoneProviding`을 통해 현재 타임존을 읽어 calculator에 전달한다.

이후 정책 우회 경로인 `toAdjustedYearMonthDayString`를 제거한다. 마지막으로 테스트와 tracker 문서를 갱신해 수용 기준 충족 여부를 확인한다.

## Concrete Steps

작업 루트: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

1. 문서화

    - `docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md` 작성
    - `docs/exec-plans/td-007-record-timezone-forward-only-execplan.md` 작성/갱신

2. 도메인/저장 경계 변경

    - `Sources/Domain/Entity/ReadingRecord.swift`에 `timeZoneID` + legacy fallback 추가
    - `Sources/Domain/Service/ReadingTimeZoneProviding.swift` 추가
    - `Sources/Domain/Calculator/ReadingScheduleCalculator.swift` write 시 `activeTimeZoneID` 반영
    - `Sources/Data/RepoImpl/SwiftDataBookRepo.swift` normalize/merge에서 `timeZoneID` 보존/기본값 처리

3. UseCase/DI 배선

    - `Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`
    - `Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
    - `Sources/App/AppDependencies.swift`

4. 정책 경로 정리

    - `Sources/Shared/Extensions/Foundation/Date+Extension.swift`의 `toAdjustedYearMonthDayString` 제거
    - `FiveGuyesTests/Domain/Policy/DayBoundaryPolicyTests.swift` 정리

5. 테스트 및 문서 동기화

    - 신규/변경 테스트 실행
    - `docs/exec-plans/tech-debt-tracker.md`와 `docs/exec-plans/architecture-debt-issue-plans.md` 업데이트

## Validation and Acceptance

- key 포맷은 `yyyy-MM-dd`로 유지된다.
- 신규/재계산 레코드는 `timeZoneID`를 가진다.
- 과거 레코드 key는 재작성되지 않는다.
- `toAdjustedYearMonthDayString(` 검색 결과가 0건이다.
- 아래 테스트가 통과한다.
  - `ReadingRecordTimeZoneTests`
  - `DayBoundaryPolicyTests`
  - `ReadingScheduleCalculatorInitialScheduleTests`
  - `ReadingScheduleCalculatorApplyTodayReadingTests`
  - `BookManagementUseCasesDailyReadingTests`
  - `BookManagementUseCasesQueryAndRegistrationTests`
  - `SwiftDataBookRepoTests`

## Idempotence and Recovery

모든 변경은 반복 적용 가능한 비파괴성 수정이다. 문제가 생기면 다음 순서로 복구한다.

1. `ReadingRecord` 확장만 롤백해 legacy decode 경계부터 복구
2. `ReadingScheduleCalculator` 시그니처 변경을 기본값 기반 호출로 축소
3. `toAdjustedYearMonthDayString` 제거가 문제면 provider 경로 테스트 먼저 복구 후 API 재추가 여부 판단

데이터 재버킷팅을 수행하지 않으므로 운영 데이터의 대량 재작성 위험은 없다.

## Artifacts and Notes

본 계획은 다음 문서를 함께 갱신한다.

- `docs/decisions/adr-0003-reading-record-key-migration-policy.md` (참조 관계 유지)
- `docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md` (신규)
- `docs/exec-plans/tech-debt-tracker.md` (TD-007 상태)
- `docs/exec-plans/architecture-debt-issue-plans.md` (이슈 실행 상태)

## Interfaces and Dependencies

최종 인터페이스:

- `protocol ReadingTimeZoneProviding { func currentTimeZoneID() -> String }`
- `struct SystemReadingTimeZoneProvider: ReadingTimeZoneProviding`
- `struct ReadingRecord { targetPages, pagesRead, timeZoneID }`

외부 라이브러리 추가는 없다. `Foundation`과 기존 도메인/유즈케이스 경계만 사용한다.

Plan revision note (2026-02-17): Initial version created to capture TD-007 follow-up scope (record-level timezone snapshot, forward-only policy, and documentation-first execution).
Plan revision note (2026-02-17): Marked implementation completion for code/test/doc sync and recorded residual scope (typed key adapter, global policy UX) as follow-up.
Plan revision note (2026-02-17): Applied F1/F4/F5 follow-up sync (local timezone bucket policy + shared timezone normalization policy + test reinforcement).
