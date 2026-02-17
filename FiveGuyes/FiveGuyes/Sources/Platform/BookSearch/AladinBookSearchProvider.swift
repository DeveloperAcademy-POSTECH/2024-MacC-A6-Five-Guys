//
//  AladinBookSearchProvider.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

import Foundation

enum BookSearchNetworkError: Error, Equatable {
    case invalidResponse
    case unexpectedStatusCode(Int)
}

final class AladinBookSearchProvider: BookSearchProviding {
    private let apiKey: String
    private let urlSession: URLSession

    private let searchBaseURL = "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx"
    private let lookupBaseURL = "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx"

    init(apiKey: String? = nil, urlSession: URLSession = .shared) {
        if let apiKey {
            self.apiKey = apiKey
        } else {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
                fatalError("API 키를 로드하지 못했습니다.")
            }
            self.apiKey = key
        }
        self.urlSession = urlSession
    }

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        let url = try makeSearchURL(query: query)
        let (data, response) = try await urlSession.data(from: url)
        try validate(response: response)
        let decodedResponse = try JSONDecoder().decode(AladinBookSearchResponseDTO.self, from: data)
        return decodedResponse.item.map { $0.toBookSearchItem() }
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        let url = try makeLookupURL(isbn: isbn)
        let (data, response) = try await urlSession.data(from: url)
        try validate(response: response)
        let decodedResponse = try JSONDecoder().decode(AladinBookDetailResponseDTO.self, from: data)
        return decodedResponse.item?.first?.subInfo?.itemPage ?? 0
    }

    private func makeSearchURL(query: String) throws -> URL {
        var components = URLComponents(string: searchBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "ttbkey", value: apiKey),
            URLQueryItem(name: "Query", value: query),
            URLQueryItem(name: "MaxResults", value: "10"),
            URLQueryItem(name: "Output", value: "js"),
            URLQueryItem(name: "Cover", value: "Big"),
            URLQueryItem(name: "Version", value: "20131101")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func makeLookupURL(isbn: String) throws -> URL {
        var components = URLComponents(string: lookupBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "ttbkey", value: apiKey),
            URLQueryItem(name: "itemIdType", value: "ISBN13"),
            URLQueryItem(name: "ItemId", value: isbn),
            URLQueryItem(name: "output", value: "js"),
            URLQueryItem(name: "Version", value: "20131101"),
            URLQueryItem(name: "OptResult", value: "itemPage")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookSearchNetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BookSearchNetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
}
