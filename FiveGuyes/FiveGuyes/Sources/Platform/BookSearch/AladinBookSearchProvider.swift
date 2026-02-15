//
//  AladinBookSearchProvider.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

import Foundation

final class AladinBookSearchProvider: BookSearchProviding {
    private let apiKey: String
    private let urlSession: URLSession

    private let searchBaseURL = "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx"
    private let lookupBaseURL = "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx"

    init(urlSession: URLSession = .shared) {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            fatalError("API 키를 로드하지 못했습니다.")
        }

        self.apiKey = key
        self.urlSession = urlSession
    }

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        let urlString = "\(searchBaseURL)?ttbkey=\(apiKey)&Query=\(query)&MaxResults=10&Output=js&Cover=Big&Version=20131101"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(AladinBookSearchResponseDTO.self, from: data)
        return response.item.map { $0.toBookSearchItem() }
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        let urlString = "\(lookupBaseURL)?ttbkey=\(apiKey)&itemIdType=ISBN13&ItemId=\(isbn)&output=js&Version=20131101&OptResult=itemPage"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await urlSession.data(from: url)
        let response = try JSONDecoder().decode(AladinBookDetailResponseDTO.self, from: data)
        return response.item?.first?.subInfo?.itemPage ?? 0
    }
}
