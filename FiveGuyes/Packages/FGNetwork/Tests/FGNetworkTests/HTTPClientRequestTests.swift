import FGNetwork
import Foundation
import Testing

@Suite("HTTPClient request 테스트")
struct HTTPClientRequestTests {
    @Test("2xx 응답을 Endpoint 응답 타입으로 디코딩")
    func request_success_decodesResponse() async throws {
        let client = HTTPClientStub { request in
            #expect(request.url.absoluteString == "https://example.com/books")
            return HTTPResponse(
                statusCode: 200,
                body: Data(#"{"value":"decoded"}"#.utf8)
            )
        }

        let response = try await client.request(TestEndpoint())

        #expect(response == TestResponse(value: "decoded"))
    }

    @Test("2xx가 아닌 응답을 본문을 포함한 unexpectedStatus로 매핑")
    func request_nonSuccess_throwsUnexpectedStatus() async {
        let responseBody = Data("server error".utf8)
        let client = HTTPClientStub { _ in
            HTTPResponse(statusCode: 503, body: responseBody)
        }

        do {
            _ = try await client.request(TestEndpoint())
            Issue.record("2xx가 아닌 응답에서 오류가 발생해야 합니다.")
        } catch let HTTPClientError.unexpectedStatus(statusCode, body) {
            #expect(statusCode == 503)
            #expect(body == responseBody)
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
    }

    @Test("잘못된 응답 본문을 decoding 오류로 매핑")
    func request_invalidBody_throwsDecodingError() async {
        let client = HTTPClientStub { _ in
            HTTPResponse(statusCode: 200, body: Data("not-json".utf8))
        }

        do {
            _ = try await client.request(TestEndpoint())
            Issue.record("잘못된 응답 본문에서 오류가 발생해야 합니다.")
        } catch HTTPClientError.decoding {
            // Expected.
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
    }
}

private struct TestEndpoint: Endpoint {
    typealias Response = TestResponse

    func makeRequest() throws(HTTPClientError) -> HTTPRequest {
        guard let url = URL(string: "https://example.com/books") else {
            throw .invalidRequest
        }
        return HTTPRequest(url: url)
    }
}

private struct TestResponse: Codable, Equatable, Sendable {
    let value: String
}

private struct HTTPClientStub: HTTPClient {
    let handler: @Sendable (HTTPRequest) async throws(HTTPClientError) -> HTTPResponse

    func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
        try await handler(request)
    }
}
