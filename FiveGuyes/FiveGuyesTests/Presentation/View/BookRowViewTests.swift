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
    @Test("출간일이 있으면 저자 괄호를 제거하고 연도를 표시한다")
    func metadataIncludesPublishedYear() throws {
        let publishedDate = try #require(
            Calendar.app.date(from: DateComponents(year: 2021, month: 4, day: 20))
        )
        let book = BookSearchItem(
            title: "소년이 온다",
            author: "한강 (지은이)",
            coverImageURL: nil,
            publisher: "창비",
            isbn13: "9788936434120",
            publishedDate: publishedDate
        )

        #expect(BookRowView.metadataText(for: book) == "한강 | 2021 | 창비")
    }

    @Test("출간일이 없으면 연도 자리를 생략한다")
    func metadataOmitsMissingPublishedYear() {
        let book = BookSearchItem(
            title: "테스트",
            author: "저자",
            coverImageURL: nil,
            publisher: "출판사",
            isbn13: nil,
            publishedDate: nil
        )

        #expect(BookRowView.metadataText(for: book) == "저자 | 출판사")
    }
}
