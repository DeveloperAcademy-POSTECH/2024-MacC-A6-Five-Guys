//
//  NationalLibraryBookDTO.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

struct NationalLibraryBookDTO: Decodable, Sendable {
    let docs: [NationalLibraryDocumentDTO]

    enum CodingKeys: CodingKey {
        case docs
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        docs = try container.decodeIfPresent([NationalLibraryDocumentDTO].self, forKey: .docs) ?? []
    }
}

struct NationalLibraryDocumentDTO: Decodable, Sendable {
    let page: String?

    enum CodingKeys: String, CodingKey {
        case page = "PAGE"
    }
}
