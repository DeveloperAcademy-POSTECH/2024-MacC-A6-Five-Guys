import Foundation

/// `URLSession` 기반 `HTTPClient` 기본 구현.
public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init() {
        self.session = URLSession(configuration: Self.makeDefaultConfiguration())
    }

    /// ephemeral + 캐시 없음 + 요청당 15초. 근거는 `services/network/module.md`를 본다.
    static func makeDefaultConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        return configuration
    }

    public init(session: URLSession) {
        self.session = session
    }

    /// 취소는 `cancelled`, 그 밖의 URLSession 오류는 `transport`로 매핑한다.
    public func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
        let urlRequest = try makeURLRequest(from: request)

        let body: Data
        let response: URLResponse
        do {
            (body, response) = try await session.data(for: urlRequest)
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw .cancelled
            }
            throw .transport(error as? URLError ?? URLError(.unknown, userInfo: [NSUnderlyingErrorKey: error]))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }
        return HTTPResponse(statusCode: httpResponse.statusCode, body: body)
    }

    private func makeURLRequest(from request: HTTPRequest) throws(HTTPClientError) -> URLRequest {
        guard var components = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            throw .invalidRequest
        }
        if !request.queryItems.isEmpty {
            var queryItems = components.queryItems ?? []
            queryItems.append(contentsOf: request.queryItems)
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw .invalidRequest
        }

        var urlRequest = URLRequest(url: url)
        request.headers.forEach { name, value in
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        if let timeout = request.timeout {
            urlRequest.timeoutInterval = timeout
        }
        return urlRequest
    }
}
