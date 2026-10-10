//
//  AladinBookSearchProvider.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

import Foundation

import FGNetwork

final class AladinBookSearchProvider: BookSearchProviding {
    private let httpClient: any HTTPClient
    private let apiKeyProvider: any APIKeyProviding

    init(httpClient: any HTTPClient, apiKeyProvider: any APIKeyProviding) {
        self.httpClient = httpClient
        self.apiKeyProvider = apiKeyProvider
    }

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        let apiKey = try resolveAPIKey()

        do {
            let response = try await httpClient.request(
                AladinSearchEndpoint(apiKey: apiKey, query: query)
            )
            return response.item.map { $0.toBookSearchItem() }
        } catch let error as HTTPClientError {
            throw map(error)
        }
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        let apiKey = try resolveAPIKey()

        do {
            let response = try await httpClient.request(
                AladinLookupEndpoint(apiKey: apiKey, isbn: isbn)
            )
            return response.item?.first?.subInfo?.itemPage ?? 0
        } catch let error as HTTPClientError {
            throw map(error)
        }
    }

    private func resolveAPIKey() throws -> String {
        do {
            return try apiKeyProvider.key(named: "API_KEY")
        } catch {
            throw BookSearchNetworkError.missingAPIKey
        }
    }

    private func map(_ error: HTTPClientError) -> any Error {
        switch error {
        case let .unexpectedStatus(statusCode, _):
            BookSearchNetworkError.unexpectedStatusCode(statusCode)
        case .invalidResponse:
            BookSearchNetworkError.invalidResponse
        case .invalidRequest:
            URLError(.badURL)
        case let .transport(error):
            error
        case let .decoding(error):
            error
        case .cancelled:
            CancellationError()
        }
    }
}
