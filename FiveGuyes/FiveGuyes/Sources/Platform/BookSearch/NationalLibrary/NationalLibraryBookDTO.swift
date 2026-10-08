//
//  NationalLibraryBookDTO.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

struct NationalLibraryBookDTO: Decodable, Sendable {
    let totalCount: String
    let docs: [NationalLibraryDocumentDTO]

    enum CodingKeys: String, CodingKey {
        case totalCount = "TOTAL_COUNT"
        case docs
    }
}

struct NationalLibraryDocumentDTO: Decodable, Sendable {
    let page: String?

    enum CodingKeys: String, CodingKey {
        case page = "PAGE"
    }
}
