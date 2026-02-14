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

        #expect(key == "2026-02-13")
    }

    @Test("adjustedDayKey - 04시부터 당일 키")
    func adjustedDayKey_atBoundary_isSameDay() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 4, minute: 0)
        let key = policy.adjustedDayKey(from: input)

        #expect(key == "2026-02-14")
    }

    @Test("Date 확장 adjustedDate는 DayBoundary 정책과 동일하게 동작")
    func dateExtension_adjustedDate_matchesPolicy() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 2, minute: 30)
        let viaExtension = input.adjustedDate()
        let viaPolicy = DayBoundary.shared.adjustedDate(from: input)

        #expect(viaExtension == viaPolicy)
    }

    @Test("Date 확장 adjusted key는 DayBoundary 정책과 동일하게 동작")
    func dateExtension_adjustedKey_matchesPolicy() {
        let input = makeDate(year: 2026, month: 2, day: 14, hour: 1, minute: 0)
        let viaExtension = input.toAdjustedYearMonthDayString()
        let viaPolicy = DayBoundary.shared.adjustedDayKey(from: input)

        #expect(viaExtension == viaPolicy)
    }
}
