//
//  FGReadingProgress+Notification.swift
//  FiveGuyes
//
//  Created by Codex on 2/12/26.
//

import Foundation

extension FGReadingProgress {
    /// 다음 독서 알림 기준 날짜를 반환합니다.
    /// lastReadDate 기준 이후(또는 오늘 이후)에서 아직 읽지 않은 첫 날짜를 찾습니다.
    func findNextReadingDay() -> Date? {
        let today = lastReadDate ?? Date()
        let todayString = today.toAdjustedYearMonthDayString()

        for dateString in dailyReadingRecords.keys.sorted() where dateString >= todayString {
            if dailyReadingRecords[dateString]?.pagesRead == 0 {
                return dateString.toDate()
            }
        }
        return nil
    }

    /// 다음 독서일 기준 일일 목표 페이지를 계산합니다.
    func findNextReadingPagesPerDay(for settings: FGUserSetting) -> Int {
        let readingPagesCalculator = ReadingPagesCalculator()
        let readingDateCalculator = ReadingDateCalculator()
        let adjustedToday = Date().adjustedDate()

        do {
            let totalDays = try readingDateCalculator.calculateValidReadingDays(
                startDate: adjustedToday,
                endDate: settings.targetEndDate,
                excludedDates: settings.excludedReadingDays
            )

            return readingPagesCalculator.calculatePagesPerDayAndRemainder(
                totalDays: totalDays,
                startPage: self.lastReadPage,
                endPage: settings.targetEndPage
            ).pagesPerDay
        } catch {
            return 1
        }
    }
}
