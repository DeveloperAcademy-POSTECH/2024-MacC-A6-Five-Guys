//
//  NationalLibraryBookDTO.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

struct NationalLibraryBookDTO: Decodable, Sendable {
    let docs: [NationalLibraryDocumentDTO]?
}

struct NationalLibraryDocumentDTO: Decodable, Sendable {
    let page: String?

    enum CodingKeys: String, CodingKey {
        case page = "PAGE"
    }
}
