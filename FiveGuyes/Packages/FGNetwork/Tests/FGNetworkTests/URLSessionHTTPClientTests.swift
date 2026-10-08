// 기본 세션 구성 팩토리는 internal이므로 직접 검증하기 위해 testable import를 사용한다.
@testable import FGNetwork
import Foundation
import os
import Testing

@Suite("URLSessionHTTPClient 테스트")
struct URLSessionHTTPClientTests {
    @Test("기본 세션은 캐시를 사용하지 않고 요청 제한 시간이 15초")
    func init_defaultSession_usesExpectedConfiguration() {
        let configuration = URLSessionHTTPClient.makeDefaultConfiguration()

        #expect(configuration.urlCache == nil)
        #expect(configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(configuration.timeoutIntervalForRequest == 15)
    }

    @Test("요청을 URLRequest로 변환하고 HTTP 응답을 그대로 반환")
    func send_response_returnsStatusHeadersAndBody() async throws {
        let stubID = UUID().uuidString
        let responseBody = Data("response".utf8)
        URLProtocolStub.register(
            .response(statusCode: 418, headers: ["X-Response": "value"], body: responseBody),
            for: stubID
        )
        defer { URLProtocolStub.unregister(stubID) }
        let client = makeClient(stubID: stubID)
        let url = try #require(URL(string: "https://example.com/books"))
        let request = HTTPRequest(
            method: .post,
            url: url,
            queryItems: [URLQueryItem(name: "query", value: "Swift & iOS")],
            headers: ["X-Request": "header"],
            body: Data("body".utf8),
            timeout: 3
        )

        let response = try await client.send(request)

        #expect(response.statusCode == 418)
        #expect(response.headers["X-Response"] == "value")
        #expect(response.body == responseBody)
        let sentRequest = try #require(URLProtocolStub.lastRequest(for: stubID))
        let components = try #require(
            sentRequest.url.map { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        )
        #expect(sentRequest.httpMethod == "POST")
        #expect(sentRequest.value(forHTTPHeaderField: "X-Request") == "header")
        #expect(bodyData(from: sentRequest) == Data("body".utf8))
        #expect(sentRequest.timeoutInterval == 3)
        #expect(components?.queryItems?.first?.name == "query")
        #expect(components?.queryItems?.first?.value == "Swift & iOS")
    }

    @Test("URL의 기존 쿼리를 보존하고 새 쿼리를 뒤에 추가")
    func send_existingQuery_preservesAndAppendsQueryItems() async throws {
        let stubID = UUID().uuidString
        URLProtocolStub.register(
            .response(statusCode: 200, headers: [:], body: Data()),
            for: stubID
        )
        defer { URLProtocolStub.unregister(stubID) }
        let client = makeClient(stubID: stubID)
        let request = HTTPRequest(
            method: .get,
            url: try #require(URL(string: "https://example.com/books?old=value")),
            queryItems: [URLQueryItem(name: "query", value: "Swift & iOS")]
        )

        _ = try await client.send(request)

        let sentRequest = try #require(URLProtocolStub.lastRequest(for: stubID))
        let components = try #require(
            sentRequest.url.map { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        )
        #expect(components?.queryItems?.count == 2)
        #expect(components?.queryItems?.first?.name == "old")
        #expect(components?.queryItems?.first?.value == "value")
        #expect(components?.queryItems?.last?.name == "query")
        #expect(components?.queryItems?.last?.value == "Swift & iOS")
    }

    @Test("전송 오류를 transport로 매핑")
    func send_transportFailure_throwsTransportError() async throws {
        let stubID = UUID().uuidString
        URLProtocolStub.register(.failure(URLError(.notConnectedToInternet)), for: stubID)
        defer { URLProtocolStub.unregister(stubID) }
        let client = makeClient(stubID: stubID)
        let request = HTTPRequest(
            method: .get,
            url: try #require(URL(string: "https://example.com"))
        )

        do {
            _ = try await client.send(request)
            Issue.record("전송 오류가 발생해야 합니다.")
        } catch let HTTPClientError.transport(error) {
            #expect(error.code == .notConnectedToInternet)
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
    }

    @Test("HTTP가 아닌 응답을 invalidResponse로 매핑")
    func send_nonHTTPResponse_throwsInvalidResponse() async throws {
        let stubID = UUID().uuidString
        URLProtocolStub.register(.nonHTTPResponse(body: Data()), for: stubID)
        defer { URLProtocolStub.unregister(stubID) }
        let client = makeClient(stubID: stubID)
        let request = HTTPRequest(
            method: .get,
            url: try #require(URL(string: "https://example.com"))
        )

        do {
            _ = try await client.send(request)
            Issue.record("HTTP가 아닌 응답에서 오류가 발생해야 합니다.")
        } catch HTTPClientError.invalidResponse {
            // Expected.
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
    }

    @Test("요청별 제한 시간을 transport timedOut으로 매핑")
    func send_timeout_throwsTimedOutTransportError() async throws {
        let stubID = UUID().uuidString
        URLProtocolStub.register(.pending, for: stubID)
        defer { URLProtocolStub.unregister(stubID) }
        let client = makeClient(stubID: stubID)
        let request = HTTPRequest(
            method: .get,
            url: try #require(URL(string: "https://example.com")),
            timeout: 1
        )

        do {
            _ = try await client.send(request)
            Issue.record("제한 시간 초과 오류가 발생해야 합니다.")
        } catch let HTTPClientError.transport(error) {
            #expect(error.code == .timedOut)
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
    }

    @Test("호출 Task 취소를 cancelled로 매핑")
    func send_taskCancellation_throwsCancelled() async throws {
        let stubID = UUID().uuidString
        URLProtocolStub.register(.pending, for: stubID)
        defer { URLProtocolStub.unregister(stubID) }
        let client = makeClient(stubID: stubID)
        let request = HTTPRequest(
            method: .get,
            url: try #require(URL(string: "https://example.com"))
        )
        let task = Task {
            try await client.send(request)
        }
        guard await waitUntil({ URLProtocolStub.didStart(for: stubID) }) else {
            task.cancel()
            Issue.record("제한 시간 안에 요청이 시작되지 않았습니다.")
            return
        }

        task.cancel()

        do {
            _ = try await task.value
            Issue.record("취소된 요청에서 오류가 발생해야 합니다.")
        } catch HTTPClientError.cancelled {
            let didStop = await waitUntil { URLProtocolStub.didStop(for: stubID) }
            #expect(didStop, "제한 시간 안에 URLProtocol 요청이 중단되어야 합니다.")
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
    }

    private func waitUntil(
        _ condition: () -> Bool,
        timeout: Duration = .seconds(1)
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(1))
        }
        return condition()
    }

    private func makeClient(stubID: String) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        configuration.httpAdditionalHeaders = ["X-Stub-ID": stubID]
        return URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    private func bodyData(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else {
                break
            }
            body.append(buffer, count: count)
        }
        return body
    }
}

private final class URLProtocolStub: URLProtocol {
    enum Stub: Sendable {
        case response(statusCode: Int, headers: [String: String], body: Data)
        case failure(URLError)
        case nonHTTPResponse(body: Data)
        case pending
    }

    private struct State: Sendable {
        var stubs: [String: Stub] = [:]
        var lastRequests: [String: URLRequest] = [:]
        var startedIDs: Set<String> = []
        var stoppedIDs: Set<String> = []
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static func register(_ stub: Stub, for id: String) {
        state.withLock { state in
            state.stubs[id] = stub
        }
    }

    static func unregister(_ id: String) {
        state.withLock { state in
            state.stubs.removeValue(forKey: id)
            state.lastRequests.removeValue(forKey: id)
            state.startedIDs.remove(id)
            state.stoppedIDs.remove(id)
        }
    }

    static func lastRequest(for id: String) -> URLRequest? {
        state.withLock { $0.lastRequests[id] }
    }

    static func didStart(for id: String) -> Bool {
        state.withLock { $0.startedIDs.contains(id) }
    }

    static func didStop(for id: String) -> Bool {
        state.withLock { $0.stoppedIDs.contains(id) }
    }

    override static func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: "X-Stub-ID") != nil
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let id = request.value(forHTTPHeaderField: "X-Stub-ID") else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let receivedRequest = request
        let stub = Self.state.withLock { state in
            state.lastRequests[id] = receivedRequest
            state.startedIDs.insert(id)
            return state.stubs[id]
        }

        guard let stub else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        switch stub {
        case let .response(statusCode, headers, body):
            sendResponse(statusCode: statusCode, headers: headers, body: body)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case let .nonHTTPResponse(body):
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            client?.urlProtocol(
                self,
                didReceive: URLResponse(
                    url: url,
                    mimeType: nil,
                    expectedContentLength: body.count,
                    textEncodingName: nil
                ),
                cacheStoragePolicy: .notAllowed
            )
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .pending:
            break
        }
    }

    private func sendResponse(statusCode: Int, headers: [String: String], body: Data) {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: statusCode,
                  httpVersion: nil,
                  headerFields: headers
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        guard let id = request.value(forHTTPHeaderField: "X-Stub-ID") else {
            return
        }
        Self.state.withLock { state in
            _ = state.stoppedIDs.insert(id)
        }
    }
}
