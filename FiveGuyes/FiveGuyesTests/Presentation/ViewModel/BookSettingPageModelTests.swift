//
//  BookSettingPageModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/16/26.
//

@testable import FiveGuyes
import Testing

@Suite("BookSettingPageModel 테스트")
@MainActor
struct BookSettingPageModelTests {
    @Test("BookSettingPageModel: 초기 페이지는 1")
    func bookSettingPage_initialPage_isOne() {
        let pageModel = BookSettingPageModel()

        #expect(pageModel.currentPage == 1)
    }

    @Test("BookSettingPageModel: previousPage 반복 호출해도 1 미만으로 내려가지 않음")
    func bookSettingPage_previousPage_clampedToMinimum() {
        let pageModel = BookSettingPageModel()

        for _ in 0..<10 {
            pageModel.previousPage()
        }

        #expect(pageModel.currentPage == 1)
    }

    @Test("BookSettingPageModel: nextPage 반복 호출해도 5 초과로 올라가지 않음")
    func bookSettingPage_nextPage_clampedToMaximum() {
        let pageModel = BookSettingPageModel()

        for _ in 0..<10 {
            pageModel.nextPage()
        }

        #expect(pageModel.currentPage == 5)
    }
}
