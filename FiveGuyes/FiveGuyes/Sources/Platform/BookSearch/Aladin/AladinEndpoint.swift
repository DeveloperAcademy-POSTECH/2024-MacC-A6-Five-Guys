//
//  AladinEndpoint.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork
import Foundation

struct AladinSearchEndpoint: Endpoint {
    typealias Response = AladinBookSearchResponseDTO

    let apiKey: String
    let query: String

    func makeRequest() throws(HTTPClientError) -> HTTPRequest {
        guard let url = URL(string: "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx") else {
            throw .invalidRequest
        }

        return HTTPRequest(
            method: .get,
            url: url,
            queryItems: [
                URLQueryItem(name: "ttbkey", value: apiKey),
                URLQueryItem(name: "Query", value: query),
                URLQueryItem(name: "MaxResults", value: "10"),
                URLQueryItem(name: "Output", value: "js"),
                URLQueryItem(name: "Cover", value: "Big"),
                URLQueryItem(name: "Version", value: "20131101")
            ]
        )
    }
}

struct AladinLookupEndpoint: Endpoint {
    typealias Response = AladinBookDetailResponseDTO

    let apiKey: String
    let isbn: String

    func makeRequest() throws(HTTPClientError) -> HTTPRequest {
        guard let url = URL(string: "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx") else {
            throw .invalidRequest
        }

        return HTTPRequest(
            method: .get,
            url: url,
            queryItems: [
                URLQueryItem(name: "ttbkey", value: apiKey),
                URLQueryItem(name: "itemIdType", value: "ISBN13"),
                URLQueryItem(name: "ItemId", value: isbn),
                URLQueryItem(name: "output", value: "js"),
                URLQueryItem(name: "Version", value: "20131101"),
                URLQueryItem(name: "OptResult", value: "itemPage")
            ]
        )
    }
}
