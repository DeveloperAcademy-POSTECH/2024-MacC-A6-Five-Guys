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
    @Test("표지 URL이 없으면 기본 표지를 사용한다")
    func missingCoverURLUsesDefaultCover() {
        #expect(BookCoverImageView.initialContent(for: nil) == .defaultCover)
    }

    @Test("A5: 출간일이 있으면 저자 괄호를 제거하고 연도를 표시한다")
    func bookRow_a5_publicationDate_showsYear() {
        let book = BookSearchItem(
            title: "소년이 온다",
            author: "한강 (지은이)",
            coverImageURL: nil,
            publisher: "창비",
            isbn13: "9788936434120",
            publishedDate: PublicationDate(year: 2021, month: 1, day: 1)
        )

        #expect(BookRowView.metadataText(for: book) == "한강 | 2021 | 창비")
    }

    @Test("A5: 연도만 있는 출간일도 연도를 표시한다")
    func bookRow_a5_yearOnlyPublicationDate_showsYear() {
        let book = BookSearchItem(
            title: "소년이 온다",
            author: "한강",
            coverImageURL: nil,
            publisher: "창비",
            isbn13: nil,
            publishedDate: PublicationDate(year: 2021)
        )

        #expect(BookRowView.metadataText(for: book) == "한강 | 2021 | 창비")
    }

    @Test("A5: 출간일이 없으면 연도 자리를 생략한다")
    func bookRow_a5_missingPublicationDate_omitsYear() {
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
