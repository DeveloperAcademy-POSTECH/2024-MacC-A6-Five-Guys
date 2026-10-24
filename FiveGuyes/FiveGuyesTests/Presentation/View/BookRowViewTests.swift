//
//  BookRowViewTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("BookRowView 테스트")
struct BookRowViewTests {
    @Test("A5: 저자 괄호를 제거하고 출간 연도가 없으면 연도 자리를 생략한다", arguments: [
        ("한강 (지은이)", PublicationDate(year: 2021, month: 1, day: 1), "한강 | 2021 | 창비"),
        ("한강", PublicationDate(year: 2021), "한강 | 2021 | 창비"),
        ("한강", nil, "한강 | 창비")
    ])
    func bookRow_a5_metadataText(author: String, publishedDate: PublicationDate?, expected: String) {
        let book = BookSearchItem(
            title: "소년이 온다",
            author: author,
            coverImageURL: nil,
            publisher: "창비",
            isbn13: nil,
            publishedDate: publishedDate
        )

        #expect(BookRowView.metadataText(for: book) == expected)
    }
}
