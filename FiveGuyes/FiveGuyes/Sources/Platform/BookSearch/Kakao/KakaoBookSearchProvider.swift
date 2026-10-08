//
//  KakaoBookSearchProvider.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork

final class KakaoBookSearchProvider: BookSearchProviding {
    private let httpClient: any HTTPClient
    private let apiKeyProvider: any APIKeyProviding

    init(httpClient: any HTTPClient, apiKeyProvider: any APIKeyProviding) {
        self.httpClient = httpClient
        self.apiKeyProvider = apiKeyProvider
    }

    func searchBooks(query: String) async throws -> [BookSearchItem] {
        let apiKey: String
        do {
            apiKey = try apiKeyProvider.key(named: "KAKAO_API_KEY")
        } catch {
            // `key(named:)`는 typed throws라 `error`가 `APIKeyError`로 추론된다.
            throw BookSearchErrorMapper.map(error)
        }

        do {
            let response = try await httpClient.request(
                KakaoBookSearchEndpoint(apiKey: apiKey, query: query)
            )
            return response.documents.map { $0.toBookSearchItem() }
        } catch {
            // `request(_:)`는 typed throws라 `error`가 `HTTPClientError`로 추론된다.
            throw BookSearchErrorMapper.map(error)
        }
    }
}
