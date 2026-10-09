//
//  BookCoverImageViewTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-09.
//

@testable import FiveGuyes
import Testing

@Suite("BookCoverImageView 테스트")
struct BookCoverImageViewTests {
    @Test("표지 URL이 없으면 기본 표지를 사용한다")
    func missingCoverURLUsesDefaultCover() {
        #expect(BookCoverImageView.url(from: nil) == nil)
    }
}
