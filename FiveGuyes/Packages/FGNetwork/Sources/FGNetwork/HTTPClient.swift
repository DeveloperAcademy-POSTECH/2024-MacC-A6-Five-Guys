import Foundation

public enum HTTPClientError: Error, Sendable {
    case invalidRequest
    case transport(URLError)
    case invalidResponse
    case unexpectedStatus(Int, Data)
    case decoding(any Error)
    case cancelled
}

public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse
}
