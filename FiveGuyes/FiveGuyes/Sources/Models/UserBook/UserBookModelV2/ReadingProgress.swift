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
    
    /// 특정 주의 기록 가져오기
    func getAdjustedWeeklyRecorded(from today: Date) -> [ReadingRecord?] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: today)?.start ?? today
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            return readingRecords[date.toYearMonthDayString()]
        }
    }
    
    // 모든 주 시작 날짜를 계산
    func getAllWeekStartDates(for settings: Settings) -> [Date] {
        let firstDate = settings.startDate
        let lastDate = settings.targetEndDate
        
        let calendar = Calendar.current
        let firstWeekStart = calendar.dateInterval(of: .weekOfMonth, for: firstDate)?.start ?? firstDate
        let lastWeekStart = calendar.dateInterval(of: .weekOfMonth, for: lastDate)?.start ?? lastDate
        
        var startDates: [Date] = []
        var currentStart = firstWeekStart
        
        while currentStart <= lastWeekStart {
            startDates.append(currentStart)
            currentStart = calendar.date(byAdding: .weekOfMonth, value: 1, to: currentStart) ?? currentStart
        }
        
        return startDates
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
        where dateString >= todayString {
            let record = readingRecords[dateString]
            if record?.pagesRead == 0 {
                return dateString.toDate()
            }
        }
        return nil
    }
    
    func findNextReadingPagesPerDay(for settings: Settings) -> Int {
        let readingScheduleCalculator = ReadingScheduleCalculator()
        return readingScheduleCalculator.calculatePagesPerDay(settings: settings, progress: self).pagesPerDay
    }
}
