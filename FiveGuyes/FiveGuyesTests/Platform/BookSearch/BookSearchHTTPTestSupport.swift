//
//  BookSearchHTTPTestSupport.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork

struct HTTPClientStub: HTTPClient {
    private let handler: @Sendable (HTTPRequest) async throws(HTTPClientError) -> HTTPResponse

    init(
        handler: @escaping @Sendable (HTTPRequest) async throws(HTTPClientError) -> HTTPResponse
    ) {
        self.handler = handler
    }

    init(error: HTTPClientError) {
        self.init { _ throws(HTTPClientError) in throw error }
    }

    func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
        try await handler(request)
    }
}

actor HTTPRequestRecorder {
    private(set) var lastRequest: HTTPRequest?

    func record(_ request: HTTPRequest) {
        lastRequest = request
    }
}
