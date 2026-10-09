# 네트워크 모듈 (FGNetwork)

외부 HTTP API를 호출하는 공통 코드. `FiveGuyes/Packages/FGNetwork`에 로컬 Swift Package로 두고, 허용 범위는 `services/_common/architecture.md`의 Local Packages 절을 따른다.

범위: HTTP 요청·응답 모델, 클라이언트 인터페이스와 URLSession 구현, 엔드포인트 추상화, API 키 저장소. 특정 API(카카오, 국립중앙도서관 등)에 대한 지식은 담지 않는다. 그것은 `services/<서비스>/`와 앱의 Platform에 있다.

## 1. 원칙

- **앱을 모른다.** Foundation만 import한다. Domain 엔티티, UseCase, 다른 패키지를 참조하지 않는다. 컴파일러가 이 방향을 막는다.
- **Swift 6 언어 모드, 모든 공개 타입은 `Sendable`.** 가변 전역 상태와 싱글턴을 두지 않는다. `Bundle`처럼 Sendable이 아닌 Foundation 타입은 보관하지 않는다.
- **오류는 typed throws.** 패키지 경계를 넘는 오류는 `HTTPClientError` 하나로 고정한다. 호출하는 쪽이 오류 종류를 전부 알고 Domain 오류로 바꾼다.
- **취소에 협조한다.** 호출한 Task가 취소되면 진행 중인 요청을 취소하고 `cancelled`로 끝낸다.

## 2. 공개 API

### 요청과 응답

| 타입 | 종류 | 내용 |
|---|---|---|
| `HTTPRequest` | struct | GET 요청. `url`, `queryItems`, `headers`, `timeout`(선택, 초) |
| `HTTPResponse` | struct | `statusCode`, `body: Data` |
| `HTTPClient` | protocol | `send(_:) async throws(HTTPClientError) -> HTTPResponse` |
| `Endpoint` | protocol | 요청 하나. `Response` 타입과 `makeRequest()` |
| `BundleAPIKeyStore` | struct | Info.plist에서 읽은 API 키 저장소 |
| `HTTPClientError` | enum | 아래 표 |

`HTTPRequest`는 `URLRequest`를 노출하지 않는다. URLSession으로의 변환은 `URLSessionHTTPClient` 안에서만 한다.

### 오류

| case | 뜻 | 호출하는 쪽의 일반적 처리 |
|---|---|---|
| `invalidRequest` | URL을 만들 수 없음 | 프로그래밍 오류. 로그 |
| `transport(URLError)` | 연결 실패, 제한 시간 초과 등 전송 단계 실패 | 네트워크 오류로 안내하거나 조용히 실패 |
| `invalidResponse` | HTTP 응답이 아님 | 서버 오류로 취급 |
| `unexpectedStatus(Int, Data)` | 2xx가 아닌 상태 코드. 본문을 함께 준다 | 상태 코드별 분기 (401 키 문제, 429 한도 등) |
| `decoding(Error)` | 응답 본문을 `Response`로 해석 실패 | 서버 응답 형식 변경 의심. 로그 |
| `cancelled` | 호출 Task가 취소됨 | 아무것도 하지 않음 |


### 규칙

- `send`는 상태 코드를 검사하지 않는다. 받은 그대로 돌려준다.
- `URLSessionHTTPClient`가 유일한 `HTTPClient` 구현이다. 기본 세션은 `.shared`가 아니라 `URLSessionConfiguration.ephemeral`이라 캐시를 쓰지 않고, 쿠키·자격증명은 디스크에 저장하지 않으며(메모리에만 보관), 데이터 수신이 없을 때의 대기 시간은 15초다(`.shared`는 60초). 엔드포인트별로 다른 값이 필요하면 `HTTPRequest.timeout`으로 재정의한다.
- 테스트와 Preview는 `HTTPClient`를 채택한 대역을 쓴다. 패키지는 대역을 제공하지 않는다.
- `request(_:)`(`HTTPClient` 확장)가 `makeRequest` → `send` → 2xx 검사(`unexpectedStatus`) → `Response` 디코딩(`decoding`)을 한 번에 한다. 디코더는 기본 `JSONDecoder`로 고정이다. 키 이름이나 날짜 해석은 DTO에서 처리한다.
- 엔드포인트 하나가 요청 하나다. API 키는 엔드포인트가 생성자 인자로 받아 `makeRequest`에서 헤더나 쿼리에 넣는다.
- `BundleAPIKeyStore`는 xcconfig 값이 치환되지 않은 채 Info.plist에 남은 경우를 잡는다. 앞뒤 공백을 지운 값이 비어 있거나 `$(`로 시작해 `)`로 끝나면 `APIKeyError.missing(name:)`이다.
- `Config.xcconfig.example`의 값은 비워 둔다. 빈 값은 `missing`으로 판정되어 설정 안내가 뜬다. `YOUR_...` 같은 가짜 값은 실제 키로 통과하므로 쓰지 않는다.
- 키 값은 로그에 남기지 않는다. 오류에도 이름만 담는다.

## 3. 앱에서 쓰는 방법

```
App/AppDependencies
  ├── URLSessionHTTPClient 1개
  ├── BundleAPIKeyStore 1개
  └── Platform provider들에 둘 다 주입

Platform/<연동>/<출처>/
  ├── <출처><동작>Endpoint     Endpoint 채택. 키·파라미터 → HTTPRequest
  ├── <출처>DTO               Response + Domain 엔티티 변환
  └── <출처>Provider          Domain의 ...Providing 채택.
                              키 꺼내기 → endpoint → client.request → 변환 → 오류 변환
```

- 이 패키지를 import하는 곳의 허용 범위는 `services/_common/architecture.md`의 Local Packages 절을 따른다.
- provider는 `HTTPClientError`와 `APIKeyError`를 Domain 오류로 바꾼다. Domain은 이 패키지의 타입을 모른다.
- provider마다 `HTTPClient`를 새로 만들지 않는다. 세션을 공유해야 연결이 재사용된다.
- 외부 형식 해석(날짜 문자열, 식별자 묶음, 자유 형식 숫자)은 DTO 변환에서 끝낸다. Domain 엔티티에는 해석된 값만 넘긴다.

## 4. 테스트

패키지 테스트는 `scripts/verify.sh`의 '패키지 테스트' 단계가 패키지 스킴으로 실행한다. 모두 Swift Testing으로 쓴다. 앱의 provider 테스트는 `HTTPClient` 대역을 주입하고 요청 내용과 DTO 변환만 검증한다.

## 5. 바꿀 때

- 공개 API를 바꾸면 이 문서의 2장을 먼저 고친다.
- 재시도, 로깅, 인증 토큰 갱신 같은 가로채기 기능은 아직 없다. 필요해지면 `HTTPClient`를 감싸는 데코레이터로 추가하고 `URLSessionHTTPClient`는 손대지 않는다.
- 이 패키지를 쓰는 연동이 늘면 3장의 폴더 규칙을 따른다. 연동별 지식은 `services/<서비스>/`에 둔다.
