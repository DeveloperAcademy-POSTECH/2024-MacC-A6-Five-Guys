import Foundation

public struct HTTPRequest: Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
    }

    public let method: Method
    public let url: URL
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let body: Data?
    public let timeout: TimeInterval?

    public init(
        method: Method,
        url: URL,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.method = method
        self.url = url
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}
