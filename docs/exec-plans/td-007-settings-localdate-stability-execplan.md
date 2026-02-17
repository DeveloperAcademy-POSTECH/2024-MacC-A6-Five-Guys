# TD-007 Settings LocalDate Stability (DateKey Parallel Fields)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/PLANS.md`.

## Purpose / Big Picture

해외 체류 중 설정한 독서 기간(start/end)이 귀국 후에도 동일한 달력 날짜로 유지되도록, 설정일 저장을 `Date` 절대시각 의존에서 `LocalDate(yyyy-MM-dd)` 중심으로 전환한다.

사용자는 기존 UI 흐름을 그대로 사용하면서도, 타임존 이동에 따라 목표일/시작일이 하루 밀리는 문제를 더 이상 경험하지 않아야 한다.

## Progress

- [x] (2026-02-17 16:45Z) 기존 TD-007 브랜치 작업을 코드/테스트/문서 3개 커밋으로 분리 완료.
- [x] (2026-02-17 16:49Z) 작업 브랜치 `bugfix/td-007-settings-localdate-stability` 생성 완료.
- [x] (2026-02-17 17:00Z) `FGUserSetting`을 DateKey source-of-truth 구조로 전환.
- [x] (2026-02-17 17:04Z) SwiftData `UserSettings`에 병행 key 필드(`startDateKey`, `targetEndDateKey`, `nonReadingDayKeys`) 추가.
- [x] (2026-02-17 17:08Z) Mapper/Repo에 key 우선 읽기 + legacy Date(Asia/Seoul) fallback + 1회 backfill 마이그레이션 반영.
- [x] (2026-02-17 17:12Z) `ReadingScheduleCalculator` 설정일 비교/제외일 계산 경계를 key 기반으로 정리.
- [x] (2026-02-17 17:16Z) `SwiftDataBookRepoTests`, `ReadingDateKeyTests`, `DayBoundaryPolicyTests`, `BookManagementUseCases*` 대상 회귀 테스트 통과.
- [x] (2026-02-17 17:28Z) 문서 동기화: tracker/architecture/product 문서에 정책/근거/후속 마이그레이션 범위 반영.

## Surprises & Discoveries

- Observation: `Date` 기반 설정값은 동일한 절대시각이어도 타임존이 바뀌면 달력 날짜가 달라질 수 있다.
  Evidence: 기존 로직에서 `settings.startDate.readingDateKey`/`settings.targetEndDate.readingDateKey` 비교 경로가 현재 타임존 해석에 의존했다.

- Observation: SwiftData `@Model`에서는 non-breaking 병행 필드 추가(`String?`, `[String]?`)가 기존 데이터 호환 측면에서 안전하다.
  Evidence: 기존 `Date` 필드를 유지한 채 key 필드를 추가하고 fetch 경계에서 1회 backfill로 운영 가능.

## Decision Log

- Decision: 설정일(start/end/non-reading)은 `Date`가 아닌 `ReadingDateKey`를 source-of-truth로 둔다.
  Rationale: 설정일은 이벤트 시각이 아니라 달력 약속이므로 LocalDate가 정확한 도메인 표현이다.
  Date/Author: 2026-02-17 / Codex

- Decision: SwiftData는 즉시 교체가 아니라 병행 필드 추가 전략을 사용한다.
  Rationale: 운영 데이터 안정성과 롤백 가능성을 유지하면서 점진 전환하기 위함.
  Date/Author: 2026-02-17 / Codex

- Decision: legacy `Date -> DateKey` 변환 기본 타임존은 `Asia/Seoul`로 고정한다.
  Rationale: 기존 제품 정책/사용자군 기준을 따르고, 여행 직후 실행 시 현재 타임존 의존 오차를 줄이기 위함.
  Date/Author: 2026-02-17 / Codex

## Outcomes & Retrospective

현재까지 코드/테스트 반영은 완료되었다. 설정일 key source-of-truth 전환으로 타임존 이동에 따른 설정일 day drift 경로를 차단했고, 저장소 경계에는 legacy backfill 경로를 추가했다.

남은 작업은 향후 `Date` 필드 제거를 위한 후속 TD 정의다. 이번 사이클에서는 병행 필드 전략만 적용하고, 파괴적 스키마 교체는 분리한다.

## Context and Orientation

관련 핵심 파일:

- `FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift`
- `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/UserSettings.swift`
- `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Extensions/UserBookV2+toFGUserBook.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/Entity/Extension/FGUserBook+toUserBookV2.swift`
- `FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`
- `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`

문제의 본질:

`Date`는 타임존 없는 절대시각이다. 설정일을 `Date`로 보관한 뒤 현재 타임존으로 날짜 키를 계산하면, 사용자가 국가를 이동했을 때 동일 값이 다른 달력 날짜로 해석될 수 있다. 반면 설정일은 "언제 읽었는가"가 아니라 "어느 날짜까지 읽을 것인가"이므로 LocalDate 표현이 맞다.

## Plan of Work

먼저 도메인 모델에서 설정일의 기준값을 `ReadingDateKey`로 옮긴다. 기존 호출부 호환을 위해 `startDate/targetEndDate/excludedReadingDays` 계산 프로퍼티는 유지한다.

다음으로 SwiftData 모델에 병행 key 필드를 추가하고, mapper에서 key 우선 읽기 정책을 적용한다. key 누락/오염 레거시는 `Asia/Seoul` 기준으로 보정한다.

마지막으로 fetch 경계에서 1회 backfill을 수행해 기존 데이터에도 key를 채우고, 계산기 경계를 key 비교로 통일한다.

## Concrete Steps

작업 루트: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

1. 모델/매핑 변경

    `FGUserSetting` key source-of-truth 전환
    `UserSettings` key 병행 필드 추가
    mapper 읽기/쓰기 정책 정렬

2. 저장소 마이그레이션

    fetch/prewarm 경계에서 settings key backfill 1회 수행

3. 계산 경계 정렬

    `ReadingScheduleCalculator`의 start/end/excluded 비교를 key 기준으로 전환

4. 회귀 검증

    `xcodebuild test -quiet -parallel-testing-enabled NO -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/SwiftDataBookRepoTests -only-testing:FiveGuyesTests/ReadingDateKeyTests -only-testing:FiveGuyesTests/DayBoundaryPolicyTests`

    `xcodebuild test -quiet -parallel-testing-enabled NO -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/BookManagementUseCasesDailyReadingTests -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests -only-testing:FiveGuyesTests/BookManagementUseCasesQueryAndRegistrationTests`

5. 문서 동기화

    `docs/decisions/adr-0005-settings-localdate-source-of-truth.md`
    `docs/exec-plans/tech-debt-tracker.md`
    `docs/exec-plans/architecture-debt-issue-plans.md`
    `docs/product/current-feature-spec.md`
    `docs/product/feature-conformance-checklist.md`
    `docs/product/past/current-diff-from-main.md`

## Validation and Acceptance

완료 조건:

1. 설정일 key가 존재할 때 읽기 로직은 key를 우선 사용한다.
2. key가 없는 legacy 데이터는 fetch 이후 key가 backfill된다.
3. 설정일 비교/정리 로직이 `Date.readingDateKey` 직접 의존 대신 setting key를 사용한다.
4. 위 테스트 명령이 모두 통과한다.
5. 문서에 "왜 Date가 문제였는지"와 "왜 LocalDate를 선택했는지"가 명시된다.

## Idempotence and Recovery

backfill 마이그레이션은 completion key를 남기는 1회 정책이다. 실패 시 앱 재실행/재호출로 재시도할 수 있고, key 필드만 채우는 비파괴성 변경이므로 기존 `Date` 데이터는 보존된다.

문제 발생 시 rollback은 `FGUserSetting`/mapper/repo 변경 커밋 단위로 분리 가능하다.

## Artifacts and Notes

관련 ADR:

- `docs/decisions/adr-0003-reading-record-key-migration-policy.md`
- `docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md`
- `docs/decisions/adr-0005-settings-localdate-source-of-truth.md` (이번 사이클 신규)

## Interfaces and Dependencies

이번 변경으로 고정되는 인터페이스:

- `FGUserSetting.startDateKey: ReadingDateKey`
- `FGUserSetting.targetEndDateKey: ReadingDateKey`
- `FGUserSetting.excludedReadingDayKeys: [ReadingDateKey]`
- `UserSettings.startDateKey: String?`
- `UserSettings.targetEndDateKey: String?`
- `UserSettings.nonReadingDayKeys: [String]?`

외부 라이브러리 추가는 없다.

Plan revision note (2026-02-17): Initial creation for TD-007 settings LocalDate stability implementation and documentation sync.
