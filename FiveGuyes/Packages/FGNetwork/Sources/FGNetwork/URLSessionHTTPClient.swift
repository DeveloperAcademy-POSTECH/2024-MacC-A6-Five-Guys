import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init() {
        self.session = URLSession(configuration: Self.makeDefaultConfiguration())
    }

    static func makeDefaultConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        return configuration
    }

    public init(session: URLSession) {
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
        let urlRequest = try makeURLRequest(from: request)

        do {
            let (body, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }

            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                headers: Self.makeHeaders(from: httpResponse),
                body: body
            )
        } catch let error as HTTPClientError {
            throw error
        } catch let error as URLError {
            if Task.isCancelled || error.code == .cancelled {
                throw .cancelled
            }
            throw .transport(error)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            if Task.isCancelled {
                throw .cancelled
            }
            throw .transport(
                URLError(.unknown, userInfo: [NSUnderlyingErrorKey: error])
            )
        }
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
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        request.headers.forEach { name, value in
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        if let timeout = request.timeout {
            urlRequest.timeoutInterval = timeout
        }
        return urlRequest
    }

    private static func makeHeaders(from response: HTTPURLResponse) -> [String: String] {
        response.allHeaderFields.reduce(into: [:]) { headers, field in
            guard let name = field.key as? String else {
                return
            }
            headers[name] = String(describing: field.value)
        }
    }
}
