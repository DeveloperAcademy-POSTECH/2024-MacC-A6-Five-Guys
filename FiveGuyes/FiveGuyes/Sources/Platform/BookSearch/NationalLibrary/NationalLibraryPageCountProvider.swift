//
//  NationalLibraryPageCountProvider.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork

final class NationalLibraryPageCountProvider: BookPageCountProviding {
    private let httpClient: any HTTPClient
    private let apiKeyProvider: any APIKeyProviding

    init(httpClient: any HTTPClient, apiKeyProvider: any APIKeyProviding) {
        self.httpClient = httpClient
        self.apiKeyProvider = apiKeyProvider
    }

    func fetchTotalPages(isbn13: String) async throws -> Int? {
        let apiKey: String
        do {
            apiKey = try apiKeyProvider.key(named: "NL_API_KEY")
        } catch {
            // `key(named:)`는 typed throws라 `error`가 `APIKeyError`로 추론된다.
            switch error {
            case let .missing(name):
                throw BookSearchError.missingAPIKey(setting: name)
            }
        }

        do {
            let response = try await httpClient.request(
                NationalLibraryISBNEndpoint(apiKey: apiKey, isbn13: isbn13)
            )
            return response.docs?.first?.page.flatMap(PageCountParser.parse)
        } catch {
            throw BookSearchError.failed
        }
    }
}
