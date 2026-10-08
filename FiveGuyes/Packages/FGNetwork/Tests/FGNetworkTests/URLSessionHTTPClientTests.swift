@testable import FGNetwork
import Foundation
import os
import Testing

@Suite("URLSessionHTTPClient 테스트")
struct URLSessionHTTPClientTests {
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
        let url = try #require(URL(string: "https://example.com/books?old=value"))
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
            timeout: 0.05
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
        while !URLProtocolStub.didStart(for: stubID) {
            await Task.yield()
        }

        task.cancel()

        do {
            _ = try await task.value
            Issue.record("취소된 요청에서 오류가 발생해야 합니다.")
        } catch HTTPClientError.cancelled {
            for _ in 0..<1_000 where !URLProtocolStub.didStop(for: stubID) {
                await Task.yield()
            }
            #expect(URLProtocolStub.didStop(for: stubID))
        } catch {
            Issue.record("예상하지 못한 오류: \(error)")
        }
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
