import Foundation

public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable

    func makeRequest() throws(HTTPClientError) -> HTTPRequest
}

public extension HTTPClient {
    func request<E: Endpoint>(_ endpoint: E) async throws(HTTPClientError) -> E.Response {
        let response = try await send(endpoint.makeRequest())
        guard (200..<300).contains(response.statusCode) else {
            throw .unexpectedStatus(response.statusCode, response.body)
        }

        do {
            return try JSONDecoder().decode(E.Response.self, from: response.body)
        } catch {
            throw .decoding(error)
        }
    }
}
