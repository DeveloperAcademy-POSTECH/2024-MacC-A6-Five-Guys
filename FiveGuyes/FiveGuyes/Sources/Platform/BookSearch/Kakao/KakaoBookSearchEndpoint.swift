//
//  KakaoBookSearchEndpoint.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import Foundation

import FGNetwork

/// 카카오 도서 검색 요청. 정확도순 10건이고 인증은 헤더로 보낸다.
struct KakaoBookSearchEndpoint: Endpoint {
    typealias Response = KakaoBookSearchResponseDTO

    let apiKey: String
    let query: String

    func makeRequest() throws(HTTPClientError) -> HTTPRequest {
        guard let url = URL(string: "https://dapi.kakao.com/v3/search/book") else {
            throw .invalidRequest
        }

        return HTTPRequest(
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
