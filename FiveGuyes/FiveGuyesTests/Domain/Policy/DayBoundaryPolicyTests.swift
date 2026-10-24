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

    @Test("adjustedDate - 04시 이전은 전날 키")
    func adjustedDate_beforeBoundary_isPreviousDayKey() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 3, minute: 59)
        let key = ReadingDateKey(date: policy.adjustedDate(from: input), calendar: .app)

        #expect(key.rawValue == "2026-02-13")
    }

    @Test("adjustedDate - 04시부터 당일 키")
    func adjustedDate_atBoundary_isSameDayKey() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 4, minute: 0)
        let key = ReadingDateKey(date: policy.adjustedDate(from: input), calendar: .app)

        #expect(key.rawValue == "2026-02-14")
    }

    @Test("DayBoundary adjustedDate는 04시 이전 시간을 전날로 조정한다")
    func adjustedDate_beforeBoundary_isPreviousDayTime() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 2, minute: 30)
        let adjusted = policy.adjustedDate(from: input)
        let expected = makeDate(year: 2026, month: 2, day: 13, hour: 22, minute: 30)

        #expect(adjusted == expected)
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

        let utcKey = ReadingDateKey(
            date: utcPolicy.adjustedDate(from: absoluteDate),
            calendar: utcCalendar
        )
        let plusNineKey = ReadingDateKey(
            date: plusNinePolicy.adjustedDate(from: absoluteDate),
            calendar: plusNineCalendar
        )

        #expect(utcKey.rawValue == "2026-02-14")
        #expect(plusNineKey.rawValue == "2026-02-15")
    }
}
