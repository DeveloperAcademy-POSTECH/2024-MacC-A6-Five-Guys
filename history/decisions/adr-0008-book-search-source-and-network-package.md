# ADR-0008: Book Search Source Replacement and Network Package Boundary

- Status: Accepted
- Date: 2026-10-08
- Owners: FiveGuyes team
- Related: [ADR-0002](adr-0002-usecase-first-boundary.md), GitHub #212, #225

## Decision

1. 도서 검색 출처를 알라딘 OpenAPI에서 **카카오 책 검색(검색)과 국립중앙도서관 ISBN 서지정보(페이지 수)** 조합으로 바꾼다. 두 출처는 Domain에서 별개의 Service interface(`BookSearchProviding`, `BookPageCountProviding`)로 두고, `BookSearchUseCase`가 조합한다.
2. HTTP 호출과 API 키 읽기는 **`FGNetwork` 로컬 Swift Package**로 분리한다. 패키지는 Swift 6 언어 모드이고 앱 타입을 모른다. 앱의 조립 코드(App)와 Platform·Data가 패키지를 import한다. Domain·Presentation·Shared는 모른다(`Presentation/Preview/`는 조립 코드로 보아 예외).
3. 출처가 주는 외부 형식(날짜 문자열, ISBN 묶음, 페이지 문자열)은 Platform 안에서 해석을 끝내고, Domain 엔티티에는 해석된 값(`Date?`, `String?`, `Int?`)만 넘긴다.
4. 검색으로 등록한 책은 ISBN-13을 함께 보관한다.
5. 앱 타깃의 Swift 6 언어 모드 전환은 이 결정에 포함하지 않는다. 공통 기반을 패키지로 분리하는 작업이 끝난 뒤 별도로 정한다.

## Context

알라딘 OpenAPI가 2026-10-30에 종료된다. 앱은 알라딘을 검색과 총 페이지 수 조회에 모두 쓰고 있다.

2026-10-08에 실제 키로 확인한 결과는 다음과 같다.

- 국립중앙도서관 ISBN 조회는 종이책 기준 약 4분의 3에서 `PAGE`를 주지만 형식이 `332`, `784 p.`, `xiii, 345 p.`처럼 제각각이다. 제목 검색은 정확도 정렬이 없어 "데미안"에 민음사 데미안이 상위에 없고, 표지도 거의 비어 있다.
- 카카오 책 검색은 다섯 개 검색어 모두 1위가 기대한 책이었고, 판본이 구분되어 나오며, 표지와 ISBN-13을 전부 줬다. 페이지 수는 없다.
- 네이버 책 검색, 도서관 정보나루에는 페이지 수가 없다. Open Library는 국내 도서 누락이 많다. Google Books는 페이지 수가 있으나 키 없이는 측정할 수 없었다.

기존 코드는 알라딘 provider 하나에 URL 조립, 상태 코드 검사, 키 검사, 디코딩이 모두 들어 있었다. 출처가 둘로 늘면 같은 코드가 두 번 생긴다. 또 알라딘의 날짜 문자열 형식이 Domain 엔티티를 거쳐 화면 코드까지 가정으로 깔려 있었다.

## Options considered

**검색·페이지 출처**

| 안 | 내용 | 판단 |
|---|---|---|
| A. 국립중앙도서관 단독 | 검색과 페이지 모두 국립중앙도서관 | 검색 품질 미달로 탈락 |
| B. 카카오 + 국립중앙도서관 | 검색은 카카오, 페이지는 ISBN-13으로 국립중앙도서관 | 채택 |
| C. 카카오 + Google Books | 페이지를 Google Books에서 | 국내 도서 채움률 미확인. 필요 시 B의 2차 출처로 추가 |

**네트워크 공통 코드 위치**

| 안 | 내용 | 판단 |
|---|---|---|
| Platform 폴더 | `Platform/Network/`에 둔다 | Swift 6 검사를 강제할 수 없고, 앱 코드 참조를 lint로만 막는다 |
| 로컬 Swift Package | `FiveGuyes/Packages/FGNetwork` | 언어 모드와 의존 방향을 컴파일러가 보장. pbxproj·스킴 편집 비용 1회. 채택 |

## Rationale

- 두 출처가 서로 다른 기능(검색, 페이지)을 맡으므로 interface를 나누면 한쪽만 교체할 수 있다. 다중 페이지 출처를 이어 붙일 때 "모름"(nil)과 "없음"(0)을 구분하기 위해 provider는 `Int?`를 돌려주고 UseCase가 0으로 바꾼다.
- 패키지는 앱 타깃을 Swift 5 모드에 둔 채로 새 코드를 Swift 6 기준으로 검증하는 유일한 방법이다. 패키지 경계에서 Sendable 위반이 드러나므로, 앱 타깃을 나중에 전환할 때 어디를 고쳐야 하는지 먼저 알 수 있다.
- 외부 형식 해석을 Platform에서 끝내는 것은 `services/_common/architecture.md`의 "외부 표현 타입은 그 layer 밖으로 노출하지 않는다"를 그대로 따른 것이다. 이번에 카카오의 ISO 날짜 형식이 기존 화면 코드와 맞지 않는 것이 그 규칙을 어겼을 때의 비용이었다.
- ISBN-13 보관은 기존 사용자의 표지 URL이 깨졌을 때 판본을 다시 찾을 유일한 식별자다. 저장 모델에 선택 필드를 더하는 비용이 작아 지금 넣는다.

## Guardrails

- 패키지는 Foundation만 import한다. 앱 코드와 다른 패키지를 참조하지 않는다.
- 패키지의 공개 타입은 `Sendable`이고, 오류는 `HTTPClientError` typed throws로 고정한다. Domain interface는 일반 `throws`를 유지한다.
- Domain과 Presentation은 패키지를 import하지 않는다.
- 페이지 조회 실패는 어떤 경우에도 등록을 막지 않는다 (`services/book-search/spec.md` B7).
- 키 값은 로그·오류·커밋에 남기지 않는다.

## Consequences

- 구현은 두 단계로 나눈다. #225에서 패키지를 만들고 알라딘 provider를 그 위로 옮긴 뒤(기본 세션이 공유 세션(60초, 캐시)에서 패키지 세션(15초, 캐시 없음)으로 바뀌는 것은 의도된 변경이다. `services/network/module.md` 참조), 다음 이슈에서 출처를 교체한다.
- `BookSearchItem`의 출간일이 `Date?`, ISBN-13이 `String?`로 바뀌어 화면의 연도 표시와 Preview 샘플 데이터가 함께 바뀐다.
- `BookMetaData`에 선택 필드가 추가된다. 경량 마이그레이션으로 충분한지 기존 데이터로 확인하고, 안 되면 스키마 버전을 올린다.
- 패키지 테스트는 `scripts/verify.sh`의 '패키지 테스트' 단계가 패키지 스킴으로 실행한다. 공유 프로젝트 스킴은 로컬 패키지 테스트 타깃을 구성원으로 인식하지 않았다.
- 두 API 키가 앱 번들에 들어간다. 공개 서지정보이고 도메인 제한이 없어 서버 경유 없이 직접 호출한다.

## Revisit criteria

- 국립중앙도서관 호출 한도가 운영 규모에 못 미치는 것으로 확인되면 페이지 조회의 서버 경유 또는 2차 출처를 다시 검토한다.
- 페이지 자동 채움 실패 비율이 사용자 불만으로 올라오면 Google Books를 2차 페이지 출처로 측정한다.
- 알림·분석 등 다른 공통 기반을 패키지로 분리한 뒤 앱 타깃의 Swift 6 전환을 결정한다.

## References

- `services/book-search/spec.md`, `services/book-search/sources.md`
- `services/network/module.md`
- 알라딘 OpenAPI 종료 공지: https://blog.aladin.co.kr/m/openapi/6695306
- 카카오 책 검색: https://developers.kakao.com/docs/latest/ko/daum-search/dev-guide#search-book
- 국립중앙도서관 ISBN 서지정보: https://www.nl.go.kr/NL/contents/N31101030500.do
