# 도서 검색 외부 출처

도서 검색 기능이 연결하는 외부 API와 그 연동 규칙. 동작 기준은 `spec.md`이고, 이 문서는 그 동작을 어떤 출처의 어떤 요청으로 얻는지를 다룬다.

범위: 검색 출처(카카오 책 검색)와 페이지 출처(국립중앙도서관 ISBN 서지정보)의 요청·응답·인증·한도·데이터 특성. 출처를 바꾸거나 추가하면 이 문서를 고치고, 결정이 바뀌면 새 ADR을 추가하고 예전 ADR에 대체 표시를 한다(`history/decisions/`).

## 인증 정보

| 설정 이름 | 용도 | 발급처 |
|---|---|---|
| `KAKAO_API_KEY` | 카카오 책 검색 REST API 키 | Kakao Developers 콘솔 > 앱 > 앱 키 > REST API 키 |
| `NL_API_KEY` | 국립중앙도서관 Open API 인증키 | 국립중앙도서관 Open API 이용 신청 (`https://www.nl.go.kr/NL/contents/N31101010000.do`) |

- 값은 `FiveGuyes/Config.xcconfig`에 넣고, 앱 타깃의 `Info.plist`가 같은 이름으로 받는다. 코드는 `Info.plist`에서만 읽는다.
- `Config.xcconfig`는 gitignore 대상이다. 키 값은 커밋·출력하지 않는다. 설정 방법은 `handbook/where/setup.md`를 본다.
- 값이 없거나 `$(KAKAO_API_KEY)`처럼 치환되지 않은 자리표시자이면 "인증 정보 없음"으로 본다. 검색 출처는 설정 안내 알림(spec A10), 페이지 출처는 조용히 0(spec B7)이다.
- 두 키 모두 앱 번들에 포함되어 추출될 수 있다. 공개 서지정보이고 도메인 제한 옵션이 없어 서버 경유 없이 클라이언트가 직접 호출한다. 한도가 문제되면 그때 다시 판단한다.

## 검색 출처: 카카오 책 검색

문서: `https://developers.kakao.com/docs/latest/ko/daum-search/dev-guide#search-book`

**요청**

```
GET https://dapi.kakao.com/v3/search/book
Authorization: KakaoAK {KAKAO_API_KEY}
query={검색어}&sort=accuracy&size=10
```

- `query`는 URL 인코딩한다. `target`은 지정하지 않는다(제목·저자·출판사·ISBN 전체).
- 한도: 일 30,000건(무료). 검색 1회가 호출 1회다.

**응답에서 쓰는 필드**

| 필드 | 형식 | 검색 항목으로 바꾸는 규칙 |
|---|---|---|
| `title` | 문자열 | 그대로 |
| `authors` | 문자열 배열 | `", "`로 이어 붙인다. 비어 있으면 빈 문자열 |
| `publisher` | 문자열 | 그대로 |
| `datetime` | ISO 8601 (`2021-04-20T00:00:00.000+09:00`) | 앞 `yyyy-MM-dd`를 달력 날짜(연·월·일)로 읽는다. 시각·오프셋은 쓰지 않는다. 형식이 다르면 nil |
| `isbn` | 공백으로 구분된 ISBN-10과 ISBN-13 (`"8936434268 9788936434267"`) | 13자리 숫자 묶음만 ISBN-13으로 쓴다. 없으면 nil |
| `thumbnail` | URL 문자열, 빈 문자열일 수 있음 | 비어 있으면 nil |

쓰지 않는 필드: `contents`, `translators`, `price`, `sale_price`, `status`, `url`.

**데이터 특성**

- 전자책 구분 필드가 없다. 전자책은 출판사가 제목에 "(전자책)"을 붙인 경우에만 알 수 있고, 일반 검색어에서는 거의 나오지 않는다.
- 같은 책의 판본(리커버, 큰글자, 에디션)이 각각 다른 ISBN-13으로 나온다. 판본 구분은 제목·출판사·출간 연도로 사용자가 한다.
- 표지는 확인한 범위에서 전부 제공됐다.

## 페이지 출처: 국립중앙도서관 ISBN 서지정보

문서: `https://www.nl.go.kr/NL/contents/N31101030500.do`

**요청**

```
GET https://www.nl.go.kr/seoji/SearchApi.do
cert_key={NL_API_KEY}&result_style=json&page_no=1&page_size=1
&isbn={ISBN-13}&ebook_yn=N
```

- `ebook_yn=N`은 전자책 기록을 제외한다(spec B4). 발행 형태 필드(`FORM`)는 오래된 종이책에서 비어 있으므로 필터로 쓰지 않는다.
- 한도: 문서에 없다. 디지털정보기획과(02-590-0548)에 문의해 확인한 값을 여기에 적는다.
- 응답이 느리거나 끊기는 경우가 있다. 요청 제한 시간은 짧게(10초 안팎) 두고, 실패는 spec B7대로 0으로 처리한다.

**응답에서 쓰는 필드**

| 필드 | 형식 | 규칙 |
|---|---|---|
| `docs[0].PAGE` | 자유 형식 문자열 | 첫 아라비아 숫자 묶음을 총 페이지 수로. spec B5 표 참고 |

쓰지 않는 필드: `TOTAL_COUNT`, `EBOOK_YN`(요청에서 걸렀으므로 확인하지 않는다), `TITLE`, `AUTHOR`, `PUBLISHER`, `TITLE_URL`(표지, 대부분 비어 있음), `FORM`, 그 외 전부.

**데이터 특성** (2026-10 확인)

- 종이책 기록은 대부분 `PAGE`가 있으나, 2015년 이전 도서와 일부 유명 도서(민음사 데미안, 창비 소년이 온다)는 비어 있다. 카카오 상위 결과 기준 약 4분의 1이 비어 있다.
- `PAGE` 형식 예는 spec B5 표를 본다.
- 제목 검색(`title=`)은 정확도 정렬이 없고 표지가 거의 없어 검색 출처로 쓰지 않는다. 같은 키로 호출되는 통합검색(`/NL/search/openApi/search.do`)에는 페이지 필드가 없다.

## 출처를 바꾸거나 추가할 때

- 검색 출처와 페이지 출처는 Domain의 interface가 따로 있다([architecture.md의 Service](../_common/architecture.md#platform)). 한쪽만 바꿀 수 있다.
- 새 출처 구현은 `FiveGuyes/FiveGuyes/Sources/Platform/BookSearch/<출처>/`에 두고, 날짜·ISBN·페이지 문자열 해석은 그 폴더 안에서 끝낸다. Domain 엔티티에는 해석된 값만 넘긴다.
- 페이지 출처를 둘 이상 이어 붙이는 규칙은 spec B9를 본다.
- 검토했으나 쓰지 않은 출처: 네이버 책 검색(페이지 없음), 도서관 정보나루(페이지 없음), Open Library(국내 도서 누락 많음), Google Books(페이지 있음, 키 필요, 국내 도서 채움률 미확인).
