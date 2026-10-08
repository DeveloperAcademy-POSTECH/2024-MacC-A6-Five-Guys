//
//  BookSearchHTTPTestSupport.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork

struct HTTPClientStub: HTTPClient {
    private enum Behavior: Sendable {
        case handler(@Sendable (HTTPRequest) async throws(HTTPClientError) -> HTTPResponse)
        case failure(HTTPClientError)
    }

    private let behavior: Behavior

    init(
        handler: @escaping @Sendable (HTTPRequest) async throws(HTTPClientError) -> HTTPResponse
    ) {
        self.behavior = .handler(handler)
    }

    init(error: HTTPClientError) {
        self.behavior = .failure(error)
    }

    func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
        switch behavior {
        case let .handler(handler):
            try await handler(request)
        case let .failure(error):
            throw error
        }
    }
}

actor HTTPRequestRecorder {
    private var requests: [HTTPRequest] = []

    func record(_ request: HTTPRequest) {
        requests.append(request)
    }

    func lastRequest() -> HTTPRequest? {
        requests.last
    }
}
