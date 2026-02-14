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
