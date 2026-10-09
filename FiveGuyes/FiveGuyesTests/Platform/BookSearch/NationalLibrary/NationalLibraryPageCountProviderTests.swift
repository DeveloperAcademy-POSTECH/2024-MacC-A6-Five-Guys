//
//  NationalLibraryPageCountProviderTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork
@testable import FiveGuyes
import Foundation
import Testing

@Suite("NationalLibraryPageCountProvider 테스트")
struct NationalLibraryPageCountProviderTests {
    @Test("국립중앙도서관 요청을 구성하고 페이지 수를 반환한다")
    func requestAndPageCountConversion() async throws {
        let recorder = HTTPRequestRecorder()
        let client = HTTPClientStub { request in
            await recorder.record(request)
            return HTTPResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"{"docs":[{"PAGE":"[130] p."}]}"#.utf8)
            )
        }
        let provider = makeProvider(httpClient: client, apiKey: "nl-key")

        let pageCount = try await provider.fetchTotalPages(isbn13: "9788936434120")

        #expect(pageCount == 130)
        let request = try #require(await recorder.lastRequest)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://www.nl.go.kr/seoji/SearchApi.do")
        #expect(request.queryItems.first(where: { $0.name == "cert_key" })?.value == "nl-key")
        #expect(request.queryItems.first(where: { $0.name == "result_style" })?.value == "json")
        #expect(request.queryItems.first(where: { $0.name == "page_no" })?.value == "1")
        #expect(request.queryItems.first(where: { $0.name == "page_size" })?.value == "1")
        #expect(request.queryItems.first(where: { $0.name == "isbn" })?.value == "9788936434120")
        #expect(request.queryItems.first(where: { $0.name == "ebook_yn" })?.value == "N")
        #expect(request.timeout == 10)
    }

    @Test("TOTAL_COUNT와 docs가 없어도 페이지 수를 모름으로 반환한다")
    func emptyDocumentsReturnNil() async throws {
        let client = HTTPClientStub { _ in
            HTTPResponse(
                statusCode: 200,
                headers: [:],
                body: Data(#"{}"#.utf8)
            )
        }
        let provider = makeProvider(httpClient: client, apiKey: "nl-key")

        #expect(try await provider.fetchTotalPages(isbn13: "9788936434120") == nil)
    }

    @Test("2xx가 아닌 응답은 failed로 변환한다")
    func nonSuccessStatusMapsToFailed() async {
        let client = HTTPClientStub { _ in
            HTTPResponse(statusCode: 404, headers: [:], body: Data())
        }
        let provider = makeProvider(httpClient: client, apiKey: "nl-key")

        await #expect(throws: BookSearchError.failed) {
            _ = try await provider.fetchTotalPages(isbn13: "9788936434120")
        }
    }

    @Test("NL_API_KEY가 없으면 설정 이름을 포함한 오류를 반환한다")
    func missingAPIKeyIncludesSettingName() async {
        let provider = NationalLibraryPageCountProvider(
            httpClient: HTTPClientStub(error: .invalidRequest),
            apiKeyProvider: BundleAPIKeyStore(values: [:])
        )

        await #expect(throws: BookSearchError.missingAPIKey(setting: "NL_API_KEY")) {
            _ = try await provider.fetchTotalPages(isbn13: "9788936434120")
        }
    }

    private func makeProvider(
        httpClient: some HTTPClient,
        apiKey: String
    ) -> NationalLibraryPageCountProvider {
        NationalLibraryPageCountProvider(
            httpClient: httpClient,
            apiKeyProvider: BundleAPIKeyStore(values: ["NL_API_KEY": apiKey])
        )
    }
}
