//
//  ReadingScheduleCalculatorInitialScheduleTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

extension ReadingScheduleCalculatorTests {
    @Test("createInitialSchedule - 정상 케이스 (나머지 없음)")
    func createInitialSchedule_noRemainder() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19")
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 10)
        #expect(result.lastReadPage == 0)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 10)
        #expect(result.dailyReadingRecords["2025-01-11"]?.targetPages == 20)
        #expect(result.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    @Test("createInitialSchedule - 나머지 있는 경우")
    func createInitialSchedule_withRemainder() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-16")
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 7)
        #expect(result.dailyReadingRecords["2025-01-14"]?.targetPages == 70)
        #expect(result.dailyReadingRecords["2025-01-15"]?.targetPages == 85)
        #expect(result.dailyReadingRecords["2025-01-16"]?.targetPages == 100)
    }

    @Test("createInitialSchedule - 제외일 있음")
    func createInitialSchedule_withExcludedDays() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19"),
            excludedReadingDays: [
                makeDate("2025-01-12"),
                makeDate("2025-01-15")
            ]
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 8)
        #expect(result.dailyReadingRecords["2025-01-12"] == nil)
        #expect(result.dailyReadingRecords["2025-01-15"] == nil)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 12)
        #expect(result.dailyReadingRecords["2025-01-11"]?.targetPages == 24)
        #expect(result.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    @Test("createInitialSchedule - 단일 날짜")
    func createInitialSchedule_singleDay() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 50,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-10")
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 1)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 50)
    }

    @Test("createInitialSchedule - 중간 페이지 시작 (30~100)")
    func createInitialSchedule_startFromMiddlePage() throws {
        let settings = makeSettings(
            startPage: 30,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-16")
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 7)
        #expect(result.lastReadPage == 29)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 39)
        #expect(result.dailyReadingRecords["2025-01-16"]?.targetPages == 100)
    }

    @Test("createInitialSchedule - 중간 페이지 + 나머지")
    func createInitialSchedule_middlePageWithRemainder() throws {
        let settings = makeSettings(
            startPage: 50,
            targetEndPage: 120,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-16")
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 7)
        #expect(result.lastReadPage == 49)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 59)
        #expect(result.dailyReadingRecords["2025-01-16"]?.targetPages == 120)
    }
}
