# ADR-0004: Reading Record TimeZone Snapshot Forward-Only Policy

- Status: Accepted
- Date: 2026-02-17
- Owners: FiveGuyes team
- Related:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0003-reading-record-key-migration-policy.md`

## Decision

`readingRecords` 저장 key는 기존처럼 `yyyy-MM-dd` 문자열을 유지한다. key에 time zone suffix를 붙이지 않고, 각 `ReadingRecord` value에 `timeZoneID`를 저장한다.

운영 정책은 forward-only로 고정한다. 즉 과거 레코드를 재버킷팅(전체 rewrite)하지 않고, 신규/재계산으로 생성되는 레코드만 현재 기기 time zone 스냅샷(`TimeZone.autoupdatingCurrent.identifier`)을 기록한다.

런타임 날짜 버킷팅 기준은 `Calendar.app`의 현재 기기 time zone(`.autoupdatingCurrent`)을 사용한다. 즉 save/read/reschedule이 동일한 현지 날짜 정책을 공유한다.

legacy 데이터(`timeZoneID` 없음)는 디코딩 시 `Asia/Seoul` 기본값을 주입해 호환한다.

## Context

ADR-0003으로 날짜 key 정책(`ReadingDateKey`, `yyyy-MM-dd`)과 호환 마이그레이션은 정리되었지만, “해외 이동 시 과거 날짜 경험 보존”은 값 레벨 메타데이터가 없어서 보장할 수 없었다.

요구사항은 다음 두 가지를 동시에 만족해야 한다.

1. 기존 key 포맷/정렬/호환성은 깨지지 않아야 한다.
2. 사용자가 time zone이 바뀌는 지역으로 이동해도 과거 기록은 당시 날짜 경험을 유지해야 한다.

## Options considered

### Option A: key suffix 저장 (`yyyy-MM-dd|Asia/Seoul`)

- 장점:
  - key만으로 time zone 정보를 조회할 수 있다.
- 미선택 이유:
  - key 파싱/정렬/비교 로직 전반을 재작성해야 하고, ADR-0003으로 안정화한 key 호환 경계를 다시 흔든다.
  - 기존 저장 데이터와 혼재 시 마이그레이션/회귀 리스크가 크다.

### Option B: record value에 `timeZoneID` 저장 (selected)

- 장점:
  - key 포맷은 유지하면서 레코드 단위 날짜 문맥을 보존할 수 있다.
  - 신규/재계산 write 경계만 통제하면 정책 적용이 가능하다.
  - legacy decode fallback으로 단계적 전환이 쉽다.

### Option C: 앱 단위/도서 단위 time zone 저장

- 장점:
  - 데이터 구조가 단순해 보인다.
- 미선택 이유:
  - 사용자가 이동한 시점 전후 레코드를 구분할 수 없어 “과거 경험 보존” 요구를 만족하지 못한다.

### Option D: 과거 데이터 full rewrite(재버킷팅)

- 장점:
  - 모든 레코드를 단일 정책으로 맞출 수 있다.
- 미선택 이유:
  - 대량 재해석/재작성은 오탐 가능성과 운영 리스크가 크고 복구 비용이 높다.
  - 현재 요구사항은 신규 경계 보강으로 충분하다.

## Why forward-only

forward-only는 기존 사용자 데이터를 건드리지 않아 운영 안전성이 높다. 이후 기록만 새 정책으로 수렴시키면 시간 경과에 따라 자연스럽게 데이터 품질이 개선된다.

## Locale and TimeZone separation

- 저장 key: `ReadingDateKey` 경계에서 `en_US_POSIX + yyyy-MM-dd`로 안정 포맷 유지.
- 날짜 버킷팅: `Calendar.app`의 현재 기기 time zone + day-boundary(04:00) 기준.
- 기록 문맥: `ReadingRecord.timeZoneID`로 레코드 생성/갱신 시점 time zone 보존.
- UI 표기 locale(`ko_KR` 등): 화면 렌더링 책임으로 유지.

즉, locale은 표기 책임, time zone은 날짜 경계 문맥 책임으로 분리한다.

## API and boundary changes

1. `ReadingRecord`에 `timeZoneID` 추가 + legacy decode fallback(`Asia/Seoul`).
2. `ReadingTimeZoneProviding` 도입:
  - `func currentTimeZoneID() -> String`
  - 시스템 구현체: `TimeZone.autoupdatingCurrent.identifier`
3. `ReadingScheduleCalculator` write 경계 메서드에 `activeTimeZoneID` 인자 추가.
4. UseCase/DI(`DailyAndPlanUseCases`, `LibraryAndRegistrationUseCases`, `AppDependencies`)에서 provider 주입.
5. `toAdjustedYearMonthDayString` 제거로 우회 경계 축소.

## Consequences

긍정적 결과:

- 해외 이동 시 신규 기록은 현지 time zone 기준으로 저장된다.
- 귀국 후에도 과거 레코드는 기존 날짜 문맥을 유지한다.
- key 포맷 불변으로 기존 정렬/비교/호환 동작을 유지한다.

남는 과제:

- 사용자가 time zone 정책을 UI에서 직접 선택/변경하는 기능은 별도 범위다.
- 글로벌 day-boundary/캘린더 정책의 전역 분리는 별도 TD에서 다룬다.

## Operational Notes

- `timeZoneID`는 "표시용 locale"이 아니라 "기록이 생성/갱신된 날짜 문맥" 보존용 메타데이터다.
- 과거 key를 재작성하지 않으므로, 운영 중 대량 데이터 rewrite 리스크가 없다.
- migration/병합에서 `legacyDefaultTimeZoneID`와 비-legacy 값이 충돌하면 비-legacy 값을 우선한다.
