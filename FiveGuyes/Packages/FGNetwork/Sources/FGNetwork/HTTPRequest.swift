import Foundation

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
