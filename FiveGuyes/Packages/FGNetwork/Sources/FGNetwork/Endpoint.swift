import Foundation

/// 한 API 호출의 URL·쿼리·헤더 조립과 응답 타입을 선언한다.
/// 응답은 기본 설정의 `JSONDecoder`로 디코딩한다.
public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable

    func makeRequest() throws(HTTPClientError) -> HTTPRequest
}

public extension HTTPClient {
    /// 2xx가 아니면 `unexpectedStatus`, 디코딩에 실패하면 `decoding`을 던진다.
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
