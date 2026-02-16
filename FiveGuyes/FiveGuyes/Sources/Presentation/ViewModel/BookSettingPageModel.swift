//
//  BookSettingPageModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 3/9/25.
//

import SwiftUI

@Observable
final class BookSettingPageModel {
    private let minimumPage = 1
    private let maximumPage = 5
    private(set) var currentPage = 1

    /// 다음 페이지로 이동
    func nextPage() {
        withAnimation(.easeOut) {
            currentPage = min(maximumPage, currentPage + 1)
        }
    }

    /// 이전 페이지로 이동
    func previousPage() {
        withAnimation(.easeOut) {
            currentPage = max(minimumPage, currentPage - 1)
        }
    }
}
