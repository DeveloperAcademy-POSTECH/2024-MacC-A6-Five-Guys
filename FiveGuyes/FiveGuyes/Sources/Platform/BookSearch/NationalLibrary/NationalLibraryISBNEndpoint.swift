//
//  NationalLibraryISBNEndpoint.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork
import Foundation

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
