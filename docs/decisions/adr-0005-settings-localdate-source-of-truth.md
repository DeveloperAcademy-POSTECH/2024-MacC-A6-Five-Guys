# ADR-0005: Settings LocalDate Source-of-Truth Policy

- Status: Accepted
- Date: 2026-02-17
- Owners: FiveGuyes team
- Related:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/exec-plans/td-007-settings-localdate-stability-execplan.md`

## Decision

독서 설정일(`startDate`, `targetEndDate`, `excludedReadingDays`)의 저장/비교 기준은 `Date` 절대시각이 아니라 `ReadingDateKey(yyyy-MM-dd)`를 source-of-truth로 사용한다.

SwiftData `UserSettings`에는 병행 필드(`startDateKey`, `targetEndDateKey`, `nonReadingDayKeys`)를 추가한다. 기존 `Date` 필드는 즉시 제거하지 않고 호환용으로 유지한다.

읽기 경계는 key 우선 정책을 적용한다. key가 없거나 오염된 legacy 데이터는 `Asia/Seoul` 기준으로 key를 생성해 1회 backfill한다.

## Context

`Date`는 절대시각이므로 같은 값이라도 타임존에 따라 달력 날짜 해석이 바뀔 수 있다. 기존 구현은 설정일을 `Date`로 저장한 뒤 런타임에서 현재 타임존 기준 `readingDateKey` 비교를 사용해, 사용자가 다른 나라로 이동하면 설정된 시작일/종료일이 하루 밀리는 리스크가 있었다.

요구사항은 다음과 같다.

1. 해외에서 설정한 날짜 경험이 귀국 후에도 동일해야 한다.
2. 현재 UX(입력 흐름/화면)는 바꾸지 않아야 한다.
3. 운영 데이터는 안전하게 점진 전환해야 한다.

## Options considered

### Option A: `Date` 유지 + settings 전용 `timeZoneID` 저장

- 장점:
  - 기존 타입 구조 변경이 작다.
- 미선택 이유:
  - 설정일은 이벤트 시각이 아니라 달력 약속이므로 타임존 재해석 자체가 불필요한 복잡도를 만든다.
  - 비교/정렬/보정 로직이 도메인 전역으로 확산될 가능성이 높다.

### Option B: LocalDate key를 source-of-truth로 전환 (selected)

- 장점:
  - 설정일 의미(달력 날짜)를 타입/저장 구조에 직접 반영한다.
  - 타임존 이동 후에도 날짜 숫자가 보존된다.
  - 계산 경계에서 비교 기준이 단순해진다.

### Option C: 기존 `Date` 필드 즉시 제거(완전 교체)

- 장점:
  - 최종 상태에 빠르게 도달한다.
- 미선택 이유:
  - 파괴적 스키마 변경 리스크가 크고 롤백 경로가 좁다.
  - 운영 안전성보다 교체 속도를 우선하게 된다.

## Why parallel fields first

이번 사이클은 병행 필드 전략을 채택한다. 기존 `Date`를 유지해 롤백 가능성을 확보하고, 읽기 key 우선 + fetch 경계 1회 backfill로 데이터 품질을 점진적으로 끌어올린다.

`Date` 필드 제거는 충분한 운영 관찰 이후 별도 TD/마이그레이션으로 분리한다.

## API and boundary changes

1. `FGUserSetting`
  - `startDateKey`, `targetEndDateKey`, `excludedReadingDayKeys` 추가
  - `startDate`, `targetEndDate`, `excludedReadingDays`는 호환용 계산 프로퍼티로 유지
2. `UserSettings`(SwiftData)
  - `startDateKey: String?`
  - `targetEndDateKey: String?`
  - `nonReadingDayKeys: [String]?`
3. mapper 정책
  - read: key 우선, legacy fallback(`Asia/Seoul`)
  - write: key + Date 동시 저장
4. repo 마이그레이션
  - fetch/prewarm 경계에서 settings key backfill 1회 실행
5. 계산 경계
  - `ReadingScheduleCalculator`의 설정일 비교/제외일 처리 기준을 key로 통일

## Consequences

긍정적 결과:

- 설정일 day drift(타임존 이동 시 하루 밀림) 리스크가 줄어든다.
- UI 변경 없이 저장 정책 안정화를 달성한다.
- 레거시 데이터도 자동 backfill로 점진 수렴한다.

남는 과제:

- SwiftData `Date` 필드의 최종 제거는 후속 마이그레이션 작업이 필요하다.
- `ReadingRecord`(event)와 `FGUserSetting`(calendar promise)의 모델 차이를 제품/개발 문서에 지속적으로 유지해야 한다.

## Operational Notes

- 이벤트 데이터(`ReadingRecord`)는 `timeZoneID`가 필요하고, 설정일 데이터(`FGUserSetting`)는 LocalDate key가 필요하다.
- 두 정책은 경쟁 관계가 아니라 역할 분리다.
- legacy fallback 기본 타임존 `Asia/Seoul`은 운영 안정성을 위한 임시 기본값이며, 향후 정책 변경 시 별도 ADR로 다룬다.
