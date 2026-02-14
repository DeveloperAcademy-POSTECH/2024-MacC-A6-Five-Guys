//
//  SDReadingProgress.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
final class ReadingProgress {
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
        DayBoundary.shared.adjustedDayKey(from: date)
    }
    
    func getAdjustedReadingRecord(for date: Date) -> ReadingRecord? {
        let dateKey = getAdjustedReadingRecordsKey(date)
        return readingRecords[dateKey]
    }
    
    /// 특정 주의 기록 가져오기
    func getAdjustedWeeklyRecorded(from today: Date) -> [ReadingRecord?] {
        let calendar = Calendar.app
        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: today)?.start ?? today
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            return readingRecords[date.toYearMonthDayString()]
        }
    }
    
    // 모든 주 시작 날짜를 계산
    // 독서 기간을 주 단위로 나눌 때 기준이 되는 시작일 목록을 만들어, 주간 요약/캘린더 계산의 기준을 맞춥니다.
    func getAllWeekStartDates(for settings: UserSettings) -> [Date] {
        settings.toFGUserSetting().weeklyStartDates(today: DayBoundary.shared.adjustedNow())
    }
    
    // ReadingProgressCalculatable 구현
    func nonZeroReadingDaysCount() -> Int {
        let readingDays = toFGReadingProgress().dailyReadingRecords.values.filter { $0.pagesRead > 0 }
        return readingDays.isEmpty ? 1 : readingDays.count
    }
    
    func findNextReadingDay(today: Date) -> Date? {
        toFGReadingProgress().findNextReadingDay(today: today)
    }
    
    // 마지막 기록 이후 남은 기간을 기준으로 다음 독서일 목표 페이지를 계산해, 사용자가 바로 다음 목표를 확인할 수 있게 합니다.
    func findNextReadingPagesPerDay(for settings: UserSettings, today: Date) -> Int {
        toFGReadingProgress().findNextReadingPagesPerDay(
            for: settings.toFGUserSetting(),
            today: today
        )
    }
}
