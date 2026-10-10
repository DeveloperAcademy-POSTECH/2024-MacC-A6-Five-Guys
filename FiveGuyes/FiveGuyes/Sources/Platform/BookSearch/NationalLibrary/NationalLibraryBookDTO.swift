//
//  NationalLibraryBookDTO.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

/// 국립중앙도서관 응답 전체. `docs`는 결과가 없으면 빠질 수 있다.
struct NationalLibraryBookDTO: Decodable, Sendable {
    let docs: [NationalLibraryDocumentDTO]?
}

struct NationalLibraryDocumentDTO: Decodable, Sendable {
    let page: String?

    enum CodingKeys: String, CodingKey {
        case page = "PAGE"
    }
}
