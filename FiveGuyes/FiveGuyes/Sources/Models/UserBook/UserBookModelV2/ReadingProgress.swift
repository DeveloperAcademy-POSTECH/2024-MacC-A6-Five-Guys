//
//  ReadingProgress.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
final class ReadingProgress: ReadingProgressProtocol {
    typealias Settings = UserSettingsProtocol
    
    var readingRecords: [String: ReadingRecord]
    var lastReadDate: Date?
    var lastPagesRead: Int = 1
    
    init(readingRecords: [String: ReadingRecord] = [:], lastReadDate: Date? = nil, lastPagesRead: Int = 1) {
        self.readingRecords = readingRecords
        self.lastReadDate = lastReadDate
        self.lastPagesRead = lastPagesRead
    }
    
    func getReadingRecordsKey(_ date: Date) -> String {
        date.toYearMonthDayString()
    }
    
    func getAdjustedReadingRecordsKey(_ date: Date) -> String {
        date.toAdjustedYearMonthDayString()
    }
    
    func getAdjustedReadingRecord(for date: Date) -> ReadingRecord? {
        let dateKey = getAdjustedReadingRecordsKey(date)
        return readingRecords[dateKey]
    }
    
    func getAdjustedWeeklyRecorded(from today: Date) -> [ReadingRecord?] {
        let calendar = Calendar.current
        let adjustedToday = calendar.date(byAdding: .hour, value: -4, to: today) ?? today
        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: adjustedToday)?.start ?? adjustedToday
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            return readingRecords[date.toYearMonthDayString()]
        }
    }
    
    // ReadingProgressCalculatable 구현
    func nonZeroReadingDaysCount() -> Int {
        let readingDays = readingRecords.values.filter { $0.pagesRead > 0 }
        return readingDays.isEmpty ? 1 : readingDays.count
    }
    
    func findNextReadingDay() -> Date? {
        let today = lastReadDate ?? Date()
        let todayString = today.toAdjustedYearMonthDayString()
        
        for dateString in readingRecords.keys.sorted()
        where dateString > todayString {
            return DateFormatter().date(from: dateString)
        }
        return nil
    }
    
    func findNextReadingPagesPerDay(for settings: Settings) -> Int {
        let readingScheduleCalculator = ReadingScheduleCalculator()
        return readingScheduleCalculator.calculatePagesPerDay(settings: settings, progress: self).pagesPerDay
    }
}
