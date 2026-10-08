//
//  KakaoBookSearchEndpoint.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork
import Foundation

struct KakaoBookSearchEndpoint: Endpoint {
    typealias Response = KakaoBookSearchResponseDTO

    let apiKey: String
    let query: String

    func makeRequest() throws(HTTPClientError) -> HTTPRequest {
        guard let url = URL(string: "https://dapi.kakao.com/v3/search/book") else {
            throw .invalidRequest
        }

        return HTTPRequest(
            method: .get,
            url: url,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "sort", value: "accuracy"),
                URLQueryItem(name: "size", value: "10")
            ],
            headers: ["Authorization": "KakaoAK \(apiKey)"]
        )
    }
}
