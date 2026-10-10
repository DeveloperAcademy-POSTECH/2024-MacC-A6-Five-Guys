//
//  BookPageSettingViewTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

@testable import FiveGuyes
import Testing

@Suite("BookPageSettingView 테스트")
struct BookPageSettingViewTests {
    @Test("총 페이지가 0이거나 시작 쪽보다 작거나 같으면 진행을 막는다")
    func invalidPageRangeReturnsMessage() {
        #expect(BookPageSettingView.pageValidationError(startPage: 1, targetEndPage: 0) != nil)
        #expect(BookPageSettingView.pageValidationError(startPage: 10, targetEndPage: 9) != nil)
        #expect(BookPageSettingView.pageValidationError(startPage: 10, targetEndPage: 10) != nil)
    }

    @Test("총 페이지가 시작 쪽보다 크면 진행을 허용한다")
    func validPageRangeReturnsNil() {
        #expect(BookPageSettingView.pageValidationError(startPage: 1, targetEndPage: 300) == nil)
    }
}
