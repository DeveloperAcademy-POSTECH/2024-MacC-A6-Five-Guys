# 네트워크 모듈 (FGNetwork)

외부 HTTP API를 호출하는 공통 코드. `FiveGuyes/Packages/FGNetwork`에 로컬 Swift Package로 두고, 앱 타깃의 Platform 구현이 가져다 쓴다.

범위: HTTP 요청·응답 모델, 클라이언트 인터페이스와 URLSession 구현, 엔드포인트 추상화, API 키 저장소. 특정 API(카카오, 국립중앙도서관 등)에 대한 지식은 담지 않는다. 그것은 `services/<서비스>/`와 앱의 Platform에 있다.

## 1. 원칙

- **앱을 모른다.** Foundation만 import한다. Domain 엔티티, UseCase, 다른 패키지를 참조하지 않는다. 컴파일러가 이 방향을 막는다.
- **Swift 6 언어 모드.** `Package.swift`에 `swiftLanguageModes: [.v6]`를 둔다. 엄격한 동시성 검사가 오류다. 앱 타깃이 Swift 5 모드여도 패키지와 그 호출 지점은 Swift 6 기준으로 검사된다.
- **모든 공개 타입은 `Sendable`.** 가변 전역 상태와 싱글턴을 두지 않는다. `JSONDecoder`, `Bundle`처럼 Sendable이 아닌 Foundation 타입은 보관하지 않는다.
- **오류는 typed throws.** 패키지 경계를 넘는 오류는 `HTTPClientError` 하나로 고정한다. 호출하는 쪽이 오류 종류를 전부 알고 Domain 오류로 바꾼다.
- **취소에 협조한다.** 호출한 Task가 취소되면 진행 중인 요청을 취소하고 `cancelled`로 끝낸다.

## 2. 공개 API

### 요청과 응답

| 타입 | 종류 | 내용 |
|---|---|---|
| `HTTPRequest` | struct | `method`(GET·POST), `url`, `queryItems`, `headers`, `body`(선택), `timeout`(선택, 초) |
| `HTTPResponse` | struct | `statusCode`, `headers`, `body: Data` |
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

### 클라이언트

```swift
public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse
}
```

- `send`는 상태 코드를 검사하지 않는다. 받은 그대로 돌려준다.
- `URLSessionHTTPClient`가 유일한 구현이다. `URLSession`을 주입받으며 기본값은 `.shared`가 아니라 패키지가 만든 세션이다(캐시 없음, 요청 제한 시간 기본 15초).
- 테스트와 Preview는 `HTTPClient`를 채택한 대역을 쓴다. 패키지는 대역을 제공하지 않는다. 각 테스트 타깃이 `@Sendable` 클로저를 담은 struct로 만든다.

### 엔드포인트

```swift
public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable
    func makeRequest() throws(HTTPClientError) -> HTTPRequest
}

extension HTTPClient {
    public func request<E: Endpoint>(_ endpoint: E) async throws(HTTPClientError) -> E.Response
}
```

- `request(_:)`가 공통 처리를 한 번에 한다. `makeRequest` → `send` → 2xx 검사(`unexpectedStatus`) → `JSONDecoder`로 `Response` 디코딩(`decoding`).
- 디코더는 호출마다 새로 만든다. 날짜·키 전략이 필요하면 `Endpoint`에 `decoder: @Sendable () -> JSONDecoder` 기본 구현을 두고 엔드포인트가 재정의한다.
- 엔드포인트 하나가 요청 하나다. API 키는 엔드포인트가 생성자 인자로 받아 `makeRequest`에서 헤더나 쿼리에 넣는다.

### API 키 저장소

```swift
public protocol APIKeyProviding: Sendable {
    func key(named name: String) throws(APIKeyError) -> String
}

public enum APIKeyError: Error, Sendable {
    case missing(name: String)   // 없음, 빈 문자열, 또는 "$(NAME)" 자리표시자
}
```

- `BundleAPIKeyStore`가 유일한 구현이다. 초기화 시 `Bundle.infoDictionary`에서 문자열 값만 `[String: String]`으로 복사하고 `Bundle`은 보관하지 않는다. 테스트는 사전을 직접 넣는 생성자를 쓴다.
- 자리표시자 판정: 앞뒤 공백을 지운 값이 비어 있거나 `$(`로 시작해 `)`로 끝나면 `missing`이다. xcconfig 값이 치환되지 않은 채 Info.plist에 남은 경우를 잡는다.
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

- provider는 `HTTPClientError`와 `APIKeyError`를 Domain 오류로 바꾼다. Domain은 이 패키지의 타입을 모른다.
- provider마다 `HTTPClient`를 새로 만들지 않는다. 세션을 공유해야 연결이 재사용된다.
- 외부 형식 해석(날짜 문자열, 식별자 묶음, 자유 형식 숫자)은 DTO 변환에서 끝낸다. Domain 엔티티에는 해석된 값만 넘긴다.

## 4. 테스트

| 대상 | 위치 | 방법 |
|---|---|---|
| `URLSessionHTTPClient` | 패키지 `Tests/FGNetworkTests` | `URLProtocol` 서브클래스 stub으로 상태 코드, 전송 오류, 제한 시간, 취소를 검증. stub의 공유 상태는 `OSAllocatedUnfairLock`으로 보호 |
| `HTTPClient.request(_:)` | 패키지 | `HTTPClient` 대역으로 2xx 검사와 디코딩 오류 매핑 검증 |
| `BundleAPIKeyStore` | 패키지 | 사전 주입으로 없음·빈 값·자리표시자 세 경우 |
| 앱의 provider | `FiveGuyesTests/Platform/` | `HTTPClient` 대역 주입. 요청 내용(URL, 쿼리, 헤더)과 DTO 변환만 검증. URLProtocol을 쓰지 않는다 |

패키지 테스트는 공유 스킴 `FiveGuyes`의 테스트 액션에 포함되어 `scripts/verify.sh`가 함께 실행한다. 모두 Swift Testing으로 쓴다.

## 5. 바꿀 때

- 공개 API를 바꾸면 이 문서의 2장을 먼저 고친다.
- 재시도, 로깅, 인증 토큰 갱신 같은 가로채기 기능은 아직 없다. 필요해지면 `HTTPClient`를 감싸는 데코레이터로 추가하고 `URLSessionHTTPClient`는 손대지 않는다.
- 이 패키지를 쓰는 연동이 늘면 3장의 폴더 규칙을 따른다. 연동별 지식은 `services/<서비스>/`에 둔다.
