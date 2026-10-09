//
//  KakaoBookSearchProviderTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork
@testable import FiveGuyes
import Foundation
import Testing

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
                headers: [:],
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

        let request = try #require(await recorder.lastRequest())
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://dapi.kakao.com/v3/search/book")
        #expect(request.headers["Authorization"] == "KakaoAK kakao-key")
        #expect(request.queryItems.first(where: { $0.name == "query" })?.value == "소년이 & 온다+")
        #expect(request.queryItems.first(where: { $0.name == "sort" })?.value == "accuracy")
        #expect(request.queryItems.first(where: { $0.name == "size" })?.value == "10")
    }

    @Test("선택 필드가 빠진 항목이 섞여 있어도 모든 문서를 변환한다")
    func missingOptionalFieldsDoNotFailResponse() async throws {
        let responseJSON = #"""
        {
          "documents": [
            {
              "title": "완전한 항목",
              "authors": ["저자"],
              "publisher": "출판사",
              "datetime": "2021-04-20T00:00:00+09:00",
              "isbn": "9788936434120",
              "thumbnail": "https://example.com/cover.jpg"
            },
            {
              "title": "선택 필드가 없는 항목"
            }
          ]
        }
        """#
        let client = HTTPClientStub { _ in
            HTTPResponse(statusCode: 200, headers: [:], body: Data(responseJSON.utf8))
        }
        let provider = makeProvider(httpClient: client, apiKey: "kakao-key")

        let books = try await provider.searchBooks(query: "테스트")

        #expect(books.map(\.title) == ["완전한 항목", "선택 필드가 없는 항목"])
        #expect(books[1].author.isEmpty)
        #expect(books[1].publisher.isEmpty)
        #expect(books[1].publishedDate == nil)
        #expect(books[1].isbn13 == nil)
        #expect(books[1].coverImageURL == nil)
    }

    @Test("2xx가 아닌 응답은 invalidResponse로 변환한다")
    func nonSuccessStatusMapsToInvalidResponse() async {
        let client = HTTPClientStub { _ in
            HTTPResponse(statusCode: 500, headers: [:], body: Data())
        }
        let provider = makeProvider(httpClient: client, apiKey: "kakao-key")

        await expectError(.invalidResponse) {
            _ = try await provider.searchBooks(query: "실패")
        }
    }

    @Test("전송 오류와 취소를 Domain 오류로 변환한다", arguments: [
        (HTTPClientError.transport(URLError(.notConnectedToInternet)), BookSearchError.network),
        (HTTPClientError.cancelled, BookSearchError.cancelled)
    ])
    func mapsHTTPClientErrors(input: (HTTPClientError, BookSearchError)) async {
        let provider = makeProvider(httpClient: HTTPClientStub(error: input.0), apiKey: "kakao-key")

        await expectError(input.1) {
            _ = try await provider.searchBooks(query: "실패")
        }
    }

    @Test("KAKAO_API_KEY가 없으면 설정 이름을 포함한 오류를 반환한다")
    func missingAPIKeyIncludesSettingName() async {
        let provider = KakaoBookSearchProvider(
            httpClient: HTTPClientStub(error: .invalidRequest),
            apiKeyProvider: BundleAPIKeyStore(values: [:])
        )

        await expectError(.missingAPIKey(setting: "KAKAO_API_KEY")) {
            _ = try await provider.searchBooks(query: "테스트")
        }
    }

    @Test("자리표시자 API 키는 누락으로 처리한다")
    func placeholderAPIKeyIsMissing() async {
        let provider = KakaoBookSearchProvider(
            httpClient: HTTPClientStub(error: .invalidRequest),
            apiKeyProvider: BundleAPIKeyStore(values: ["KAKAO_API_KEY": "$(KAKAO_API_KEY)"])
        )

        await expectError(.missingAPIKey(setting: "KAKAO_API_KEY")) {
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

    private func expectError(
        _ expectedError: BookSearchError,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            Issue.record("오류가 발생해야 합니다.")
        } catch let error as BookSearchError {
            #expect(error == expectedError)
        } catch {
            Issue.record("예상하지 못한 오류 타입: \(error)")
        }
    }
}
