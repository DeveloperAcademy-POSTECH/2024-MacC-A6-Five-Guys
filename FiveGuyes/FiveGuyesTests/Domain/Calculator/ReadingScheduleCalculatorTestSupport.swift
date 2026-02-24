//
//  ReadingScheduleCalculatorTestSupport.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("ReadingScheduleCalculator 테스트")
struct ReadingScheduleCalculatorTests {
    let calculator = ReadingScheduleCalculator()

    func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }

    func makeSettings(
        startPage: Int = 1,
        targetEndPage: Int = 100,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date] = []
    ) -> FGUserSetting {
        FGUserSetting(
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    func makeProgressWithReadingHistory(
        startDate: Date,
        endDate: Date,
        startPage: Int = 1,
        targetEndPage: Int = 100,
        excludedDays: [Date] = [],
        readDates: [Date: Int] = [:]
    ) throws -> FGReadingProgress {
        var settings = makeSettings(
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            targetEndDate: endDate,
            excludedReadingDays: excludedDays
        )

        var progress = try calculator.createInitialSchedule(settings: settings)

        for (date, pagesRead) in readDates.sorted(by: { $0.key < $1.key }) {
            let result = try calculator.applyTodayReading(
                settings: settings,
                progress: progress,
                pagesRead: pagesRead,
                date: date
            )
            progress = result.progress
            if let updatedSettings = result.updatedSettings {
                settings = updatedSettings
            }
        }

        return progress
    }
}
