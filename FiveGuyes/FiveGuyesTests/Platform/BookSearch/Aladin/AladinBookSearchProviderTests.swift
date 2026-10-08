//
//  AladinBookSearchProviderTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2026-02-16.
//

import FGNetwork
@testable import FiveGuyes
import Foundation
import Testing

@Suite("AladinBookSearchProvider 테스트")
struct AladinBookSearchProviderTests {
    @Test("fetchBooks는 특수문자 query와 ttbkey를 인코딩하고 결과를 디코딩")
    func aladinProvider_fetchBooks_encodesQueryAndDecodesItems() async throws {
        let recorder = HTTPRequestRecorder()
        let client = HTTPClientStub { request in
            await recorder.record(request)
            return HTTPResponse(
                statusCode: 200,
                headers: [:],
                body: Data(
                    #"{"item":[{"title":"Swift & iOS","author":"Tester","cover":null,"publisher":"FG","isbn13":"9781234567890","pubDate":"20250101"}]}"#.utf8
                )
            )
        }
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        let books = try await provider.fetchBooks(query: "스위프트 & iOS+")

        #expect(books.count == 1)
        #expect(books.first?.title == "Swift & iOS")
        let request = try #require(await recorder.lastRequest())
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx")
        #expect(request.queryItems.first(where: { $0.name == "ttbkey" })?.value == "testKey")
        #expect(request.queryItems.first(where: { $0.name == "Query" })?.value == "스위프트 & iOS+")
        #expect(request.queryItems.first(where: { $0.name == "MaxResults" })?.value == "10")
        #expect(request.queryItems.first(where: { $0.name == "Output" })?.value == "js")
        #expect(request.queryItems.first(where: { $0.name == "Cover" })?.value == "Big")
        #expect(request.queryItems.first(where: { $0.name == "Version" })?.value == "20131101")
    }

    @Test("fetchBooks는 2xx가 아닌 HTTP 응답을 명시 오류로 매핑")
    func aladinProvider_fetchBooks_nonSuccessStatus_throwsMappedError() async {
        let client = HTTPClientStub(error: .unexpectedStatus(500, Data("{}".utf8)))
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        do {
            _ = try await provider.fetchBooks(query: "실패")
            Issue.record("500 응답에서 오류가 발생해야 합니다.")
        } catch let error as BookSearchNetworkError {
            #expect(error == .unexpectedStatusCode(500))
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBooks는 HTTP가 아닌 응답 오류를 invalidResponse로 매핑")
    func aladinProvider_fetchBooks_invalidResponse_throwsMappedError() async {
        let client = HTTPClientStub(error: .invalidResponse)
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        do {
            _ = try await provider.fetchBooks(query: "실패")
            Issue.record("HTTP가 아닌 응답에서 오류가 발생해야 합니다.")
        } catch let error as BookSearchNetworkError {
            #expect(error == .invalidResponse)
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBooks는 전송 오류의 URLError를 그대로 전파")
    func aladinProvider_fetchBooks_transportError_rethrowsURLError() async {
        let client = HTTPClientStub(error: .transport(URLError(.notConnectedToInternet)))
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        do {
            _ = try await provider.fetchBooks(query: "실패")
            Issue.record("전송 오류가 발생해야 합니다.")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBooks는 디코딩 오류를 그대로 전파")
    func aladinProvider_fetchBooks_decodingError_rethrowsDecodingError() async {
        let decodingError = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "invalid payload")
        )
        let client = HTTPClientStub(error: .decoding(decodingError))
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        do {
            _ = try await provider.fetchBooks(query: "실패")
            Issue.record("디코딩 오류가 발생해야 합니다.")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "invalid payload")
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBooks는 cancelled를 CancellationError로 전파")
    func aladinProvider_fetchBooks_cancelled_throwsCancellationError() async {
        let client = HTTPClientStub(error: .cancelled)
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        do {
            _ = try await provider.fetchBooks(query: "취소")
            Issue.record("취소 오류가 발생해야 합니다.")
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBooks는 invalidRequest를 badURL로 전파")
    func aladinProvider_fetchBooks_invalidRequest_throwsBadURLError() async {
        let client = HTTPClientStub(error: .invalidRequest)
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        do {
            _ = try await provider.fetchBooks(query: "잘못된 요청")
            Issue.record("잘못된 URL 오류가 발생해야 합니다.")
        } catch let error as URLError {
            #expect(error.code == .badURL)
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }

    @Test("fetchBooks는 API_KEY가 빈 문자열이면 missingAPIKey 오류를 반환")
    func aladinProvider_fetchBooks_emptyAPIKey_throwsMissingAPIKey() async {
        await expectMissingAPIKey(apiKey: "") { provider in
            _ = try await provider.fetchBooks(query: "테스트")
        }
    }

    @Test("fetchBookTotalPages는 API_KEY가 공백 문자열이면 missingAPIKey 오류를 반환")
    func aladinProvider_fetchBookTotalPages_whitespaceAPIKey_throwsMissingAPIKey() async {
        await expectMissingAPIKey(apiKey: "   ") { provider in
            _ = try await provider.fetchBookTotalPages(isbn: "9781234567890")
        }
    }

    @Test("fetchBooks는 미치환 플레이스홀더 API_KEY에서 missingAPIKey 오류를 반환")
    func aladinProvider_fetchBooks_unresolvedPlaceholderAPIKey_throwsMissingAPIKey() async {
        await expectMissingAPIKey(apiKey: "$(API_KEY)") { provider in
            _ = try await provider.fetchBooks(query: "테스트")
        }
    }

    @Test("fetchBookTotalPages는 ItemId와 ttbkey를 인코딩하고 페이지 수를 반환")
    func aladinProvider_fetchBookTotalPages_encodesISBNAndReturnsPageCount() async throws {
        let recorder = HTTPRequestRecorder()
        let client = HTTPClientStub { request in
            await recorder.record(request)
            return HTTPResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"{"item":[{"subInfo":{"itemPage":321}}]}"#.utf8)
            )
        }
        let provider = makeProvider(httpClient: client, apiKey: "testKey")

        let totalPages = try await provider.fetchBookTotalPages(isbn: "978-1 2345&67890")

        #expect(totalPages == 321)
        let request = try #require(await recorder.lastRequest())
        #expect(request.url.absoluteString == "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx")
        #expect(request.queryItems.first(where: { $0.name == "ttbkey" })?.value == "testKey")
        #expect(request.queryItems.first(where: { $0.name == "ItemId" })?.value == "978-1 2345&67890")
        #expect(request.queryItems.first(where: { $0.name == "itemIdType" })?.value == "ISBN13")
        #expect(request.queryItems.first(where: { $0.name == "output" })?.value == "js")
        #expect(request.queryItems.first(where: { $0.name == "OptResult" })?.value == "itemPage")
    }

    private func makeProvider(
        httpClient: some HTTPClient,
        apiKey: String
    ) -> AladinBookSearchProvider {
        AladinBookSearchProvider(
            httpClient: httpClient,
            apiKeyProvider: BundleAPIKeyStore(values: ["API_KEY": apiKey])
        )
    }

    private func expectMissingAPIKey(
        apiKey: String,
        operation: (AladinBookSearchProvider) async throws -> Void
    ) async {
        let client = HTTPClientStub(error: .invalidRequest)
        let provider = makeProvider(httpClient: client, apiKey: apiKey)

        do {
            try await operation(provider)
            Issue.record("유효하지 않은 API_KEY에서 missingAPIKey 오류가 발생해야 합니다.")
        } catch let error as BookSearchNetworkError {
            #expect(error == .missingAPIKey)
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }
}

private struct HTTPClientStub: HTTPClient {
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

private actor HTTPRequestRecorder {
    private var requests: [HTTPRequest] = []

    func record(_ request: HTTPRequest) {
        requests.append(request)
    }

    func lastRequest() -> HTTPRequest? {
        requests.last
    }
}
