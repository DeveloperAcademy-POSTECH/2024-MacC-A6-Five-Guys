//
//  BookSettingPageModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 3/9/25.
//

import SwiftUI

@Observable
final class BookSettingPageModel {
    private(set) var currentPage = 1
    
    /// 다음 페이지로 이동
    func nextPage() {
        withAnimation(.easeOut) {
            currentPage += 1
        }
    }

    /// 이전 페이지로 이동
    func previousPage() {
        withAnimation(.easeOut) {
            currentPage = max(1, currentPage - 1)
        }
    }
}
