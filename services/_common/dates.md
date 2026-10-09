# 날짜와 시간

> 앱이 다루는 날짜·시간 값의 종류와 각 종류를 다루는 방식을 정한 목표 문서다. 각 값의 규칙은 요지만 적고, 이유와 세부는 링크한 서비스 문서와 ADR이 가진다.

## 1. 값의 종류

| 종류 | 뜻 | 시각에서 만들 때 필요한 시간대 | Swift 표현 |
|---|---|---|---|
| 시각(instant) | 지구 어딘가의 한 순간 | 해당 없음(절대) | `Date` |
| 달력 날짜(civil date) | "며칠"이라는 하루 | 필요(어느 달력·시간대로 자르는지가 따라붙는다) | `ReadingDateKey`(`yyyy-MM-dd` 문자열) |
| 부분 날짜 | 연도는 있고 월·일은 없을 수 있는 달력 날짜 | 해당 없음(시각에서 만들지 않는다) | `PublicationDate` |
| 하루 중 시각(time of day) | 날짜 없이 "몇 시 몇 분"만 | 필요(해석할 때 그날의 시간대) | 시·분 정수 |

## 2. 앱의 날짜 값

| 값 | 종류 | 시간대 기준 | 만드는 곳 | 저장 | 규칙이 있는 곳 |
|---|---|---|---|---|---|
| 독서 기록일 | 달력 날짜 | 기기 시간대. 기록마다 만들 때의 시간대 ID를 함께 저장 | Domain(`ReadingDateKey`) | `yyyy-MM-dd` 문자열 키 | 기록마다 생성 시점 시간대 ID를 저장. 과거 기록은 재계산하지 않음(forward-only). [ADR-0004](../../history/decisions/adr-0004-reading-record-timezone-forward-only-policy.md) |
| 독서 설정일(시작·목표·쉬는 날) | 달력 날짜 | 기기 시간대 | Domain(`ReadingDateKey`) | 키 필드가 기준, `Date` 필드는 호환용으로 유지 | 키 문자열이 기준. legacy `Date` 필드는 읽기 호환용. [ADR-0005](../../history/decisions/adr-0005-settings-localdate-source-of-truth.md) |
| 오늘 | 달력 날짜 | 기기 시간대에 하루 경계 정책을 적용 | Domain(`ReadingDateProviding` → `DayBoundaryProviding`) | 저장 안 함 | 하루 경계는 기기 시간대 04:00, `DayBoundaryProviding`이 정함. [알림 명세](../notification/spec.md) 1장(하루 경계) (주인 문서는 #234) |
| 출간일 | 부분 날짜 | 없음 | Platform이 출처 문자열에서 해석 | 저장 안 함 | 출처 문자열의 달력 날짜만 읽고 월·일은 없을 수 있음. [도서 검색 명세](../book-search/spec.md) A5 |
| 알림 발송 시각 | 하루 중 시각 | 기기 시간대 | Data(UserDefaults) | 시·분 정수 | 시·분 정수, 기기 시간대로 해석. [알림 명세](../notification/spec.md) 3장 |

## 3. 공통 규칙

- 달력 날짜를 `Date`로 들지 않는다. 읽는 시간대에 따라 날짜가 바뀐다. 독서 기록일·설정일·오늘은 `ReadingDateKey`로 다루고 비교한다.
- 외부가 주는 날짜 문자열은 Platform 규칙을 따른다 ([Platform](architecture.md#platform)).
- 하루 경계는 `DayBoundaryProviding` 한 곳에서만 정한다. 하루 경계를 맞추려고 시(hour) 단위로 보정하는 코드를 다른 곳에 두지 않는다.
- 화면 표기 포맷은 `Shared/Extensions/Foundation/Date+Extension.swift`에 모은다. View에서 `DateFormatter`를 직접 만들지 않는다.
- 날짜 계산·버킷팅은 `Calendar.app`(기기 시간대)을 쓰고, 키 문자열은 `ReadingDateKey`가 `en_US_POSIX`로 만든다.

## 4. 바꿀 때

- 새 날짜 값이 생기면 2장 표에 한 줄 추가하고, 규칙은 해당 서비스 문서에 적는다.
- 값의 종류를 바꾸는 결정(예: 시각 → 달력 날짜)은 ADR을 남긴다.
