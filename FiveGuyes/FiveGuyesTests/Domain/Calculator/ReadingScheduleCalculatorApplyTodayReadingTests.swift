//
//  ReadingScheduleCalculatorApplyTodayReadingTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

extension ReadingScheduleCalculatorTests {
    @Test("applyTodayReading - 목표 달성")
    func applyTodayReading_targetMet() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 10,
            date: makeDate("2025-01-10")
        )

        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(result.progress.lastReadPage == 10)
        #expect(result.updatedSettings == nil)
        #expect(result.progress.dailyReadingRecords.count == 10)
        #expect(result.progress.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    @Test("applyTodayReading - 목표 초과 → 재조정")
    func applyTodayReading_exceedsTarget() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 30,
            date: makeDate("2025-01-10")
        )

        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 30)
        #expect(result.progress.lastReadPage == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 47)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    @Test("applyTodayReading - 목표 미달 → 재조정")
    func applyTodayReading_underTarget() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 10,
            date: makeDate("2025-01-10")
        )

        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 10)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(result.progress.lastReadPage == 10)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 32)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    @Test("applyTodayReading - 제외일에 읽기")
    func applyTodayReading_onExcludedDay() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14"),
            excludedReadingDays: [
                makeDate("2025-01-11")
            ]
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 30,
            date: makeDate("2025-01-11")
        )

        #expect(result.updatedSettings != nil)
        #expect(result.updatedSettings?.excludedReadingDays.isEmpty == true)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.pagesRead == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 30)
        #expect(result.progress.dailyReadingRecords.count == 5)
        #expect(result.progress.dailyReadingRecords["2025-01-12"]?.targetPages == 53)
        #expect(result.progress.dailyReadingRecords["2025-01-13"]?.targetPages == 76)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 0)
    }

    @Test("applyTodayReading - 시작일 이전 기록 시 시작일부터 재분배")
    func applyTodayReading_beforeStartDate_recalculateFromStartDate() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-20"),
            targetEndDate: makeDate("2025-01-24")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 30,
            date: makeDate("2025-01-15")
        )

        #expect(result.updatedSettings == nil)
        #expect(result.progress.lastReadPage == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-15"]?.pagesRead == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-15"]?.targetPages == 30)

        #expect(result.progress.dailyReadingRecords["2025-01-16"] == nil)
        #expect(result.progress.dailyReadingRecords["2025-01-19"] == nil)

        #expect(result.progress.dailyReadingRecords["2025-01-20"]?.targetPages == 44)
        #expect(result.progress.dailyReadingRecords["2025-01-24"]?.targetPages == 100)
        #expect(result.progress.dailyReadingRecords.count == 6)
    }

    @Test("applyTodayReading - 중간 페이지 독서 진행")
    func applyTodayReading_middlePage() throws {
        let settings = makeSettings(
            startPage: 30,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        #expect(progress.dailyReadingRecords["2025-01-10"]?.targetPages == 43)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 50,
            date: makeDate("2025-01-10")
        )

        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 50)
        #expect(result.progress.lastReadPage == 50)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 62)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    @Test("applyTodayReading - 중간 날짜 조기 완독 시 미래 목표를 제거")
    func applyTodayReading_earlyCompletionRemovesFutureTargets() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 100,
            date: makeDate("2025-01-11")
        )

        #expect(result.progress.lastReadPage == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 20)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.pagesRead == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-12"] == nil)
        #expect(result.progress.dailyReadingRecords["2025-01-14"] == nil)
        #expect(result.progress.dailyReadingRecords.count == 2)
    }

    @Test("applyTodayReading - 제외일 조기 완독 시 제외일 해제와 미래 목표 제거를 함께 보장")
    func applyTodayReading_onExcludedDayEarlyCompletion_updatesSettingsAndRemovesFutureTargets() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14"),
            excludedReadingDays: [makeDate("2025-01-11")]
        )

        let progress = try calculator.createInitialSchedule(settings: settings)

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 100,
            date: makeDate("2025-01-11")
        )

        #expect(result.updatedSettings != nil)
        #expect(result.updatedSettings?.excludedReadingDays.isEmpty == true)
        #expect(result.progress.lastReadPage == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 25)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.pagesRead == 100)
        #expect(result.progress.dailyReadingRecords["2025-01-12"] == nil)
        #expect(result.progress.dailyReadingRecords["2025-01-14"] == nil)
        #expect(result.progress.dailyReadingRecords.count == 2)
    }

    @Test("applyTodayReading - 타임존 변경 후 기존 기록은 유지되고 신규/재계산 기록만 새 타임존을 사용")
    func applyTodayReading_keepsLegacyRecordTimeZoneAndUsesActiveTimeZoneForNewWrites() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-12")
        )

        let initial = try calculator.createInitialSchedule(
            settings: settings,
            activeTimeZoneID: "Asia/Seoul"
        )

        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: initial,
            pagesRead: 40,
            date: makeDate("2025-01-11"),
            activeTimeZoneID: "America/Los_Angeles"
        )

        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.timeZoneID == "Asia/Seoul")
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.timeZoneID == "America/Los_Angeles")
        #expect(result.progress.dailyReadingRecords["2025-01-12"]?.timeZoneID == "America/Los_Angeles")

        let keys = Set(result.progress.dailyReadingRecords.keys)
        #expect(keys == ["2025-01-10", "2025-01-11", "2025-01-12"])
    }
}
