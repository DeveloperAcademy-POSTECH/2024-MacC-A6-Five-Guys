//
//  BookSettingInputModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/8/24.
//

import SwiftUI

@Observable
final class BookSettingInputModel {
    private(set) var selectedBook: Book?
    private(set) var startPage = 1
    private(set) var targetEndPage = 1
    private(set) var startData: Date?
    private(set) var endData: Date?
    private(set) var nonReadingDays: [Date] = []
    
    func setSelectedBook(_ book: Book) {
        self.selectedBook = book
    }
    
    func setPageRange(start: Int = 1, end: Int) {
        self.startPage = start
        self.targetEndPage = end
    }
    
    func setReadingPeriod(startDate: Date?, endDate: Date?) {
        self.startData = startDate
        self.endData = endDate
    }
    
    func setNonReadingDays(_ days: [Date]) {
        self.nonReadingDays = days
    }
    
    func clearSelectedBook() {
        selectedBook = nil
    }
    
    func clearPageRange() {
        startPage = 1
        targetEndPage = 1
    }
    
    func clearReadingPeriod() {
        startData = nil
        endData = nil
    }
    
    func clearNonReadingDays() {
        nonReadingDays.removeAll()
    }
}
