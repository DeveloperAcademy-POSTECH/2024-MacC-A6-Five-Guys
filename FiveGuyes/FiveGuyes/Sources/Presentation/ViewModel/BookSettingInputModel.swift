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
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    private(set) var nonReadingDays: [Date] = []
    
    func setSelectedBook(_ book: Book) {
        self.selectedBook = book
    }
    
    func setPageRange(start: Int = 1, end: Int) {
        self.startPage = start
        self.targetEndPage = end
    }
    
    func setReadingPeriod(startDate: Date?, endDate: Date?) {
        self.startDate = startDate
        self.endDate = endDate
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
        startDate = nil
        endDate = nil
    }
    
    func clearNonReadingDays() {
        nonReadingDays.removeAll()
    }
}
