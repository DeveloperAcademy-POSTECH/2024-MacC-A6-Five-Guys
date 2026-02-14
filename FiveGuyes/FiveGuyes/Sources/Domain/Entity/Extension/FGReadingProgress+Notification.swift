//
//  FGReadingProgress+Notification.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/12/26.
//

import Foundation

extension FGReadingProgress {
    /// 다음 독서 알림 기준 날짜를 반환합니다.
    /// 기준일(04:00 규칙으로 정규화된 날짜) 이후에서 아직 읽지 않은 첫 날짜를 찾습니다.
    func findNextReadingDay(today: Date) -> Date? {
        let lowerBoundDate = max(lastReadDate ?? today, today)
        let lowerBoundKey = lowerBoundDate.toYearMonthDayString()

        for dateString in dailyReadingRecords.keys.sorted() where dateString >= lowerBoundKey {
            if dailyReadingRecords[dateString]?.pagesRead == 0 {
                return dateString.toDate()
            }
        }
        return nil
    }

    /// 다음 독서일 기준 일일 목표 페이지를 계산합니다.
    func findNextReadingPagesPerDay(
        for settings: FGUserSetting,
        today: Date
    ) -> Int {
        let pageMath = PageMathCalculator()
        let dateMath = DateMathCalculator()

        do {
            let totalDays = try dateMath.validDays(
                from: today,
                to: settings.targetEndDate,
                excluding: settings.excludedReadingDays
            )

            let nextPage = nextStartPage(settings: settings)
            let result = try pageMath.dividePages(
                from: nextPage,
                to: settings.targetEndPage,
                over: totalDays
            )

            return result.daily
        } catch {
            return 1
        }
    }

    private func nextStartPage(settings: FGUserSetting) -> Int {
        let nextPageFromRecords = dailyReadingRecords.values
            .map(\.pagesRead)
            .filter { $0 > 0 }
            .max()
            .map { $0 + 1 }

        let fallbackNextPage = max(lastReadPage + 1, settings.startPage)
        let candidate = nextPageFromRecords ?? fallbackNextPage

        return min(max(candidate, settings.startPage), settings.targetEndPage)
    }
}
