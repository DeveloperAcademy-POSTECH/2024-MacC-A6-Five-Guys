# ADR-0009: Publication Date as a Partial Civil Date

- Status: Accepted
- Date: 2026-10-09
- Owners: FiveGuyes team
- Related: [ADR-0008](adr-0008-book-search-source-and-network-package.md), GitHub #228, #231

## Decision

1. 출간일은 시간대 없는 **부분 달력 날짜**(연도 필수, 월·일 선택)를 나타내는 값 타입으로 Domain에 둔다. 시각(`Date`)으로 들지 않는다.
2. 카카오가 주는 문자열(`2021-01-01T00:00:00.000+09:00`)은 Platform에서 앞 `yyyy-MM-dd`만 읽어 이 타입으로 바꾼다. 시간과 오프셋은 버린다.
3. View는 연도만 본다. `Comparable`, 포매팅, 저장은 쓰는 곳이 생길 때 만든다.

해석 동작은 `services/book-search/spec.md` A5를 본다.

## Context

ADR-0008은 외부 형식을 Platform에서 해석하고 Domain에는 `Date?`를 넘기기로 했다. 카카오의 출간일 `2021-01-01T00:00:00.000+09:00`을 #228 초안에서 `Date`(시각)로 들었더니, 기기 시간대가 한국(UTC+9)보다 서쪽이면 같은 시각이 2020-12-31이라 연도가 전년도로 보였다.

출간일은 "그날"을 뜻하는 달력 날짜인데 타입이 시각이어서 뜻과 모양이 어긋난 것이 원인이다.

## Options considered

| 안 | 내용 | 판단 |
|---|---|---|
| A. `Date` 유지 + View에서 시간대를 한국으로 고정 | 화면에서 연도를 뽑을 때 시간대를 지정한다 | 한 줄이지만 View가 카카오의 형식을 알게 되고, 다음 출처가 오면 다시 열어야 한다 |
| B. 연도만 (`Int`) | 연도 하나만 보관한다 | YAGNI로는 허용되지만 값의 의미보다 좁다 |
| C. 부분 달력 날짜 | 연도 필수, 월·일 선택 | 채택 |

## Rationale

- 뜻과 모양을 맞춘다. 증상(화면의 연도)을 변환으로 덮지 않고 원인(타입)을 고친다. 고치는 위치는 카카오 형식을 아는 Platform이다.
- 출판 날짜는 "2021년"처럼 연도만 알려진 경우가 있는 정보라, 값의 의미에 맞는 모양은 부분 날짜다. 날짜 표준 EDTF(ISO 8601-2에 편입)도 `YYYY`, `YYYY-MM`, `YYYY-MM-DD`를 Level 0에 포함한다. Google Books처럼 가변 정밀도로 주는 출처가 있다는 점은 이 의미의 예시일 뿐, 후속 후보로 가정한 것이 아니다.
- YAGNI와 충돌하지 않는다. YAGNI는 필요하리라 가정한 기능을 미리 넣는 것을 막는다. 필드를 선택으로 두는 것은 대비가 아니라 값의 의미를 맞추는 일이고, 정렬·저장·포매팅 같은 기능은 만들지 않았다.
- "이 값은 UTC 정오다" 같은 약속 대신 타입으로 강제하면 컴파일러가 어긋남을 잡는다.

## Consequences

- ADR-0008 Decision 3의 `Date?`는 이 결정으로 대체된다.
- `BookSearchItem`의 출간일은 값 타입이 되고 화면은 연도를 읽는다. 기기 시간대와 무관하다.
- 새 출처가 월·일 없는 날짜를 주어도 Domain은 바뀌지 않는다.
- 후속 출처가 연도보다 좁은 정밀도(분기 등)를 주면 이 결정을 다시 본다.

## References

- John Ousterhout, *A Philosophy of Software Design* — 변경 증폭(change amplification)
- Martin Fowler, [Yagni](https://www.martinfowler.com/bliki/Yagni.html) — YAGNI는 가정한 기능에 적용되고, 고치기 쉽게 만드는 노력에는 적용되지 않는다
- Alexis King, [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) — 경계에서 한 번 해석해 타입으로 넘긴다
- Library of Congress, [Extended Date/Time Format](https://www.loc.gov/standards/datetime/) — 부분 날짜의 표준 표현
