//
//  NationalLibraryISBNEndpoint.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import Foundation

import FGNetwork

/// 종이책(`ebook_yn=N`) 한 건만 조회한다. 검색 뒤 이어지는 부가 호출이라 타임아웃을 10초로 짧게 둔다.
struct NationalLibraryISBNEndpoint: Endpoint {
    typealias Response = NationalLibraryBookDTO

    let apiKey: String
    let isbn13: String

    func makeRequest() throws(HTTPClientError) -> HTTPRequest {
        guard let url = URL(string: "https://www.nl.go.kr/seoji/SearchApi.do") else {
            throw .invalidRequest
        }

        return HTTPRequest(
            url: url,
            queryItems: [
                URLQueryItem(name: "cert_key", value: apiKey),
                URLQueryItem(name: "result_style", value: "json"),
                URLQueryItem(name: "page_no", value: "1"),
                URLQueryItem(name: "page_size", value: "1"),
                URLQueryItem(name: "isbn", value: isbn13),
                URLQueryItem(name: "ebook_yn", value: "N")
            ],
            timeout: 10
        )
    }
}
