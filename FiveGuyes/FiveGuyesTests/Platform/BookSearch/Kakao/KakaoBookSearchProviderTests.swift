//
//  KakaoBookSearchProviderTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

@testable import FiveGuyes
import Foundation
import Testing

import FGNetwork

@Suite("KakaoBookSearchProvider 테스트")
struct KakaoBookSearchProviderTests {
    @Test("카카오 요청과 검색 결과 변환 규칙을 적용한다")
    func requestAndDTOConversion() async throws {
        let recorder = HTTPRequestRecorder()
        let responseJSON = #"""
        {
          "documents": [
            {
              "title": "소년이 온다",
              "authors": ["한강", "공저자"],
              "publisher": "창비",
              "datetime": "2021-04-20T00:00:00.000+09:00",
              "isbn": "8936434128 9788936434120",
              "thumbnail": "https://example.com/cover.jpg"
            },
            {
              "title": "ISBN-10만 있는 책",
              "isbn": "1234567890"
            }
          ]
        }
        """#
        let client = HTTPClientStub { request in
            await recorder.record(request)
            return HTTPResponse(
                statusCode: 200,
                body: Data(responseJSON.utf8)
            )
        }
        let provider = makeProvider(httpClient: client, apiKey: "kakao-key")

        let books = try await provider.searchBooks(query: "소년이 & 온다+")

        #expect(books.count == 2)
        #expect(books[0].author == "한강, 공저자")
        #expect(books[0].isbn13 == "9788936434120")
        #expect(books[0].coverImageURL == "https://example.com/cover.jpg")
        #expect(books[0].publishedDate == PublicationDate(year: 2021, month: 4, day: 20))
        #expect(books[1].author.isEmpty)
        #expect(books[1].publisher.isEmpty)
        #expect(books[1].isbn13 == nil)
        #expect(books[1].coverImageURL == nil)
        #expect(books[1].publishedDate == nil)

        let request = try #require(await recorder.lastRequest)
        #expect(request.url.absoluteString == "https://dapi.kakao.com/v3/search/book")
        #expect(request.headers["Authorization"] == "KakaoAK kakao-key")
        #expect(request.queryItems.first(where: { $0.name == "query" })?.value == "소년이 & 온다+")
        #expect(request.queryItems.first(where: { $0.name == "sort" })?.value == "accuracy")
        #expect(request.queryItems.first(where: { $0.name == "size" })?.value == "10")
    }

    @Test("2xx가 아닌 응답은 failed로 변환한다")
    func nonSuccessStatusMapsToFailed() async {
        let client = HTTPClientStub { _ in
            HTTPResponse(statusCode: 500, body: Data())
        }
        let provider = makeProvider(httpClient: client, apiKey: "kakao-key")

        await #expect(throws: BookSearchError.failed) {
            _ = try await provider.searchBooks(query: "실패")
        }
    }

    @Test("전송 오류와 취소를 failed로 변환한다", arguments: [
        HTTPClientError.transport(URLError(.notConnectedToInternet)),
        HTTPClientError.cancelled
    ])
    func mapsHTTPClientErrors(error: HTTPClientError) async {
        let provider = makeProvider(httpClient: HTTPClientStub(error: error), apiKey: "kakao-key")

        await #expect(throws: BookSearchError.failed) {
            _ = try await provider.searchBooks(query: "실패")
        }
    }

    @Test("KAKAO_API_KEY가 없으면 설정 이름을 포함한 오류를 반환한다")
    func missingAPIKeyIncludesSettingName() async {
        let provider = KakaoBookSearchProvider(
            httpClient: HTTPClientStub(error: .invalidRequest),
            apiKeyProvider: BundleAPIKeyStore(values: [:])
        )

        await #expect(throws: BookSearchError.missingAPIKey(setting: "KAKAO_API_KEY")) {
            _ = try await provider.searchBooks(query: "테스트")
        }
    }

    private func makeProvider(
        httpClient: some HTTPClient,
        apiKey: String
    ) -> KakaoBookSearchProvider {
        KakaoBookSearchProvider(
            httpClient: httpClient,
            apiKeyProvider: BundleAPIKeyStore(values: ["KAKAO_API_KEY": apiKey])
        )
    }
}
