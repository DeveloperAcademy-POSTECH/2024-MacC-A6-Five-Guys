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
        } catch let error as APIKeyError {
            throw BookSearchErrorMapper.map(error)
        }

        do {
            let response = try await httpClient.request(
                NationalLibraryISBNEndpoint(apiKey: apiKey, isbn13: isbn13)
            )
            guard let page = response.docs.first?.page else { return nil }
            return PageCountParser.parse(page)
        } catch let error as HTTPClientError {
            throw BookSearchErrorMapper.map(error)
        }
    }
}
