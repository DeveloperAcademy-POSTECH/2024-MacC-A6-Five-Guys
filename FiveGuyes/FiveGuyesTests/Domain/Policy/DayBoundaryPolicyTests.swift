//
//  DayBoundaryPolicyTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("DayBoundary 정책 테스트")
struct DayBoundaryPolicyTests {
    private let policy = DefaultDayBoundaryPolicy()

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = Calendar.app.timeZone

        guard let date = Calendar.app.date(from: components) else {
            fatalError("Invalid date components")
        }
        return date
    }

    @Test("adjustedDayKey - 04시 이전은 전날 키")
    func adjustedDayKey_beforeBoundary_isPreviousDay() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 3, minute: 59)
        let key = policy.adjustedDayKey(from: input)

        #expect(key.rawValue == "2026-02-13")
    }

    @Test("adjustedDayKey - 04시부터 당일 키")
    func adjustedDayKey_atBoundary_isSameDay() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 4, minute: 0)
        let key = policy.adjustedDayKey(from: input)

        #expect(key.rawValue == "2026-02-14")
    }

    @Test("DayBoundary adjustedDate는 04시 이전 시간을 전날로 조정한다")
    func adjustedDate_beforeBoundary_isPreviousDayTime() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 2, minute: 30)
        let adjusted = DayBoundary.shared.adjustedDate(from: input)
        let expected = makeDate(year: 2026, month: 2, day: 13, hour: 22, minute: 30)

        #expect(adjusted == expected)
    }

    @Test("ReadingDateProvider.dayKey는 DayBoundary 정책과 동일하게 동작")
    func readingDateProvider_dayKey_matchesPolicy() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 1, minute: 0)
        let provider = DefaultReadingDateProvider()
        let viaProvider = provider.dayKey(from: input)
        let viaPolicy = DayBoundary.shared.adjustedDayKey(from: input)

        #expect(viaProvider == viaPolicy)
    }

    @Test("DayBoundary는 calendar 타임존에 따라 날짜 키 결과가 달라질 수 있다")
    func dayBoundary_respectsInjectedCalendarTimeZone() {
        var utcCalendar = Calendar(identifier: .gregorian)
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0),
              let plusNineTimeZone = TimeZone(secondsFromGMT: 9 * 60 * 60) else {
            Issue.record("Invalid time zone fixture")
            return
        }
        utcCalendar.timeZone = utcTimeZone

        var utcComponents = DateComponents()
        utcComponents.year = 2026
        utcComponents.month = 2
        utcComponents.day = 14
        utcComponents.hour = 20
        utcComponents.minute = 30
        utcComponents.timeZone = utcTimeZone

        guard let absoluteDate = utcCalendar.date(from: utcComponents) else {
            Issue.record("Invalid absolute date fixture")
            return
        }

        var plusNineCalendar = Calendar(identifier: .gregorian)
        plusNineCalendar.timeZone = plusNineTimeZone

        let utcPolicy = DefaultDayBoundaryPolicy(dayStartHour: 4, calendar: utcCalendar)
        let plusNinePolicy = DefaultDayBoundaryPolicy(dayStartHour: 4, calendar: plusNineCalendar)

        let utcKey = utcPolicy.adjustedDayKey(from: absoluteDate)
        let plusNineKey = plusNinePolicy.adjustedDayKey(from: absoluteDate)

        #expect(utcKey.rawValue == "2026-02-14")
        #expect(plusNineKey.rawValue == "2026-02-15")
    }
}
