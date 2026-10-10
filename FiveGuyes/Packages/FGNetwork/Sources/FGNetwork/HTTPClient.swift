import Foundation

/// `HTTPClient`가 던지는 오류.
public enum HTTPClientError: Error, Sendable {
    /// URL·쿼리 조립에 실패했다.
    case invalidRequest
    /// URLSession 오류. 타임아웃도 여기에 속한다.
    case transport(URLError)
    /// HTTP 응답이 아니다.
    case invalidResponse
    /// 2xx 밖의 상태 코드. 상태 코드와 본문을 담는다.
    case unexpectedStatus(Int, Data)
    /// JSON 디코딩에 실패했다.
    case decoding(any Error)
    /// Task가 취소됐다.
    case cancelled
}

/// 요청을 보내고 상태 코드 판정 없이 응답을 그대로 돌려준다.
/// 2xx 판정과 디코딩은 `Endpoint`용 `request(_:)` 확장이 한다.
public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse
}
