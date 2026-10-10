import Foundation

/// GET 요청 한 건의 재료. `timeout`이 nil이면 세션 기본값을 쓴다.
public struct HTTPRequest: Sendable {
    public let url: URL
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let timeout: TimeInterval?

    public init(
        url: URL,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil
    ) {
        self.url = url
        self.queryItems = queryItems
        self.headers = headers
        self.timeout = timeout
    }
}
