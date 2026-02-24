//
//  ReadingScheduleCalculatorRescheduleTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

extension ReadingScheduleCalculatorTests {
    @Test("adjustFutureTargets - 정상 재조정")
    func adjustFutureTargets_normal() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")
        )

        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-14"),
            readDates: [
                makeDate("2025-01-10"): 30
            ]
        )

        let result = try calculator.adjustFutureTargets(
            settings: settings,
            progress: progress,
            fromDate: makeDate("2025-01-10")
        )

        #expect(result.dailyReadingRecords["2025-01-10"]?.pagesRead == 30)
        #expect(result.dailyReadingRecords["2025-01-11"]?.pagesRead == 0)
        #expect(result.dailyReadingRecords["2025-01-11"]?.targetPages == 47)
        #expect(result.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    @Test("adjustFutureTargets - 유효 독서일 0일이면 calculationFailed")
    func adjustFutureTargets_noValidDays_throwsCalculationFailed() {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-10"),
            excludedReadingDays: [makeDate("2025-01-10")]
        )

        let progress = FGReadingProgress(
            dailyReadingRecords: [
                makeDate("2025-01-09").toYearMonthDayString(): ReadingRecord(targetPages: 10, pagesRead: 10)
            ],
            lastReadDate: makeDate("2025-01-09"),
            lastReadPage: 10
        )

        do {
            _ = try calculator.adjustFutureTargets(
                settings: settings,
                progress: progress,
                fromDate: makeDate("2025-01-09")
            )
            Issue.record("Expected calculationFailed error but succeeded")
        } catch let error as ScheduleCalculationError {
            switch error {
            case .calculationFailed(let underlying):
                guard let mathError = underlying as? PageMathCalculator.MathError else {
                    Issue.record("Expected PageMathCalculator.MathError as underlying")
                    return
                }

                #expect({
                    if case .divisionByZero = mathError { return true }
                    return false
                }(), "Expected divisionByZero, got \(mathError)")
            default:
                Issue.record("Expected calculationFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected ScheduleCalculationError, got \(error)")
        }
    }

    @Test("rescheduleOnAppOpen - 정상 재분배")
    func rescheduleOnAppOpen_normal() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19")
        )

        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-19"),
            readDates: [
                makeDate("2025-01-10"): 10
            ]
        )

        #expect(progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(progress.dailyReadingRecords["2025-01-11"]?.pagesRead == 0)
        #expect(progress.dailyReadingRecords.count == 10)

        let result = try calculator.rescheduleOnAppOpen(
            settings: settings,
            progress: progress,
            today: makeDate("2025-01-13")
        )

        #expect(result.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 10)
        #expect(result.dailyReadingRecords["2025-01-13"]?.targetPages == 22)
        #expect(result.dailyReadingRecords["2025-01-14"]?.targetPages == 35)
        #expect(result.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    @Test("rescheduleOnAppOpen - targetDatePassed 에러")
    func rescheduleOnAppOpen_targetDatePassed() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-15")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        #expect(throws: ScheduleCalculationError.self) {
            try calculator.rescheduleOnAppOpen(
                settings: settings,
                progress: progress,
                today: makeDate("2025-01-20")
            )
        }
    }

    @Test("rescheduleOnAppOpen - 오늘 이미 읽음")
    func rescheduleOnAppOpen_alreadyReadToday() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-15")
        )

        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-15"),
            readDates: [
                makeDate("2025-01-10"): 16,
                makeDate("2025-01-12"): 50
            ]
        )

        #expect(progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 16)
        #expect(progress.dailyReadingRecords["2025-01-12"]?.pagesRead == 50)
        #expect(progress.lastReadPage == 50)
        #expect(progress.dailyReadingRecords["2025-01-13"]?.targetPages == 66)
        #expect(progress.dailyReadingRecords["2025-01-14"]?.targetPages == 83)
        #expect(progress.dailyReadingRecords["2025-01-15"]?.targetPages == 100)

        let result = try calculator.rescheduleOnAppOpen(
            settings: settings,
            progress: progress,
            today: makeDate("2025-01-12")
        )

        #expect(result.lastReadPage == 50)
        #expect(result.dailyReadingRecords["2025-01-10"]?.pagesRead == 16)
        #expect(result.dailyReadingRecords["2025-01-12"]?.pagesRead == 50)
        #expect(result.dailyReadingRecords["2025-01-13"]?.targetPages == 66)
        #expect(result.dailyReadingRecords["2025-01-14"]?.targetPages == 83)
        #expect(result.dailyReadingRecords["2025-01-15"]?.targetPages == 100)
    }

    @Test("rescheduleForSettingsChange - 시작일 미래로 변경")
    func rescheduleForSettingsChange_futureStartDate() throws {
        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-20"),
            readDates: [
                makeDate("2025-01-10"): 10
            ]
        )

        #expect(progress.dailyReadingRecords["2025-01-10"]?.targetPages == 10)

        let newSettings = makeSettings(
            startDate: makeDate("2025-01-25"),
            targetEndDate: makeDate("2025-02-05")
        )

        let result = try calculator.rescheduleForSettingsChange(
            newSettings: newSettings,
            progress: progress,
            today: makeDate("2025-01-15")
        )

        #expect(result.dailyReadingRecords["2025-01-10"] == nil)
        #expect(result.dailyReadingRecords["2025-01-25"] != nil)
    }

    @Test("rescheduleForSettingsChange - 종료일 변경")
    func rescheduleForSettingsChange_endDateChanged() throws {
        let newSettings = makeSettings(
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-25")
        )

        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-20"),
            readDates: [
                makeDate("2025-01-10"): 30
            ]
        )

        #expect(progress.dailyReadingRecords["2025-01-25"] == nil)

        let result = try calculator.rescheduleForSettingsChange(
            newSettings: newSettings,
            progress: progress,
            today: makeDate("2025-01-12")
        )

        #expect(result.dailyReadingRecords["2025-01-25"] != nil)
    }
}
