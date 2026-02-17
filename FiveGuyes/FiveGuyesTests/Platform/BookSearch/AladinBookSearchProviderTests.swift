//
//  AladinBookSearchProviderTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2026-02-16.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("AladinBookSearchProvider 테스트")
struct AladinBookSearchProviderTests {
    @Test("fetchBooks는 특수문자 query를 인코딩해 요청하고 결과를 디코딩")
    func aladinProvider_fetchBooks_encodesQueryAndDecodesItems() async throws {
        let stubID = UUID().uuidString
        let session = makeStubSession(stubID: stubID)
        URLProtocolStub.registerHandler(for: stubID) { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {
              "item": [
                {
                  "title": "Swift & iOS",
                  "author": "Tester",
                  "cover": null,
                  "publisher": "FG",
                  "isbn13": "9781234567890",
                  "pubDate": "20250101"
                }
              ]
            }
            """.data(using: .utf8) ?? Data()
            return (response, data)
        }
        defer {
            URLProtocolStub.unregisterHandler(for: stubID)
        }

        let provider = AladinBookSearchProvider(apiKey: "testKey", urlSession: session)
        let books = try await provider.fetchBooks(query: "스위프트 & iOS+")

        #expect(books.count == 1)
        #expect(books.first?.title == "Swift & iOS")

        guard let requestURL = URLProtocolStub.lastRequest(for: stubID)?.url else {
            Issue.record("요청 URL이 기록되지 않았습니다.")
            return
        }
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        #expect(queryItems.first(where: { $0.name == "ttbkey" })?.value == "testKey")
        #expect(queryItems.first(where: { $0.name == "Query" })?.value == "스위프트 & iOS+")
    }

    @Test("fetchBooks는 2xx가 아닌 HTTP 응답을 명시 오류로 매핑")
    func aladinProvider_fetchBooks_nonSuccessStatus_throwsMappedError() async throws {
        let stubID = UUID().uuidString
        let session = makeStubSession(stubID: stubID)
        URLProtocolStub.registerHandler(for: stubID) { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data("{}".utf8)
            return (response, data)
        }
        defer {
            URLProtocolStub.unregisterHandler(for: stubID)
        }

        let provider = AladinBookSearchProvider(apiKey: "testKey", urlSession: session)

        do {
            _ = try await provider.fetchBooks(query: "실패")
            Issue.record("500 응답에서 오류가 발생해야 합니다.")
        } catch let error as BookSearchNetworkError {
            #expect(error == .unexpectedStatusCode(500))
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBookTotalPages는 ItemId를 인코딩해 요청하고 페이지 수를 반환")
    func aladinProvider_fetchBookTotalPages_encodesISBNAndReturnsPageCount() async throws {
        let stubID = UUID().uuidString
        let session = makeStubSession(stubID: stubID)
        URLProtocolStub.registerHandler(for: stubID) { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {
              "item": [
                {
                  "subInfo": {
                    "itemPage": 321
                  }
                }
              ]
            }
            """.data(using: .utf8) ?? Data()
            return (response, data)
        }
        defer {
            URLProtocolStub.unregisterHandler(for: stubID)
        }

        let provider = AladinBookSearchProvider(apiKey: "testKey", urlSession: session)
        let totalPages = try await provider.fetchBookTotalPages(isbn: "978-1 2345&67890")

        #expect(totalPages == 321)

        guard let requestURL = URLProtocolStub.lastRequest(for: stubID)?.url else {
            Issue.record("요청 URL이 기록되지 않았습니다.")
            return
        }
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        #expect(queryItems.first(where: { $0.name == "ItemId" })?.value == "978-1 2345&67890")
    }

    private func makeStubSession(stubID: String) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        configuration.httpAdditionalHeaders = ["X-Stub-ID": stubID]
        return URLSession(configuration: configuration)
    }
}

private final class URLProtocolStub: URLProtocol {
    private static let lock = NSLock()
    private static var handlers: [String: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
    private static var lastRequests: [String: URLRequest] = [:]

    static func registerHandler(
        for stubID: String,
        _ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) {
        lock.lock()
        handlers[stubID] = handler
        lock.unlock()
    }

    static func unregisterHandler(for stubID: String) {
        lock.lock()
        handlers.removeValue(forKey: stubID)
        lastRequests.removeValue(forKey: stubID)
        lock.unlock()
    }

    static func lastRequest(for stubID: String) -> URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return lastRequests[stubID]
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: "X-Stub-ID") != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let stubID = request.value(forHTTPHeaderField: "X-Stub-ID") else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        Self.lock.lock()
        let requestHandler = Self.handlers[stubID]
        Self.lastRequests[stubID] = request
        Self.lock.unlock()

        guard let requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
