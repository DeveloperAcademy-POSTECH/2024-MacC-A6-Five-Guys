//
//  BookSettingInputModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/8/24.
//

import SwiftUI

@Observable
final class BookSettingInputModel {
    var currentPage = BookSettingsPage.bookSearch.rawValue
    var selectedBook: Book?
    var startPage = 1
    var targetEndPage = 1
    var startData: Date?
    var endData: Date?
    var nonReadingDays: [Date] = []
    
    func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }

}
