//
//  SettingsDateKeyPolicyTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/17/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("SettingsDateKeyPolicy 테스트")
struct SettingsDateKeyPolicyTests {
    private func makeUTCDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = calendar.timeZone

        guard let date = calendar.date(from: components) else {
            fatalError("Invalid UTC date fixture")
        }
        return date
    }

    @Test("유효한 raw key는 그대로 유지한다")
    func resolveDateKey_keepsValidRawKey() {
        let legacyDate = makeUTCDate(year: 2026, month: 2, day: 10, hour: 18)

        let resolved = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: "2026-03-01",
            legacyDate: legacyDate
        )

        #expect(resolved.rawValue == "2026-03-01")
    }

    @Test("invalid 또는 nil raw key는 Asia/Seoul legacy date로 fallback한다")
    func resolveDateKey_fallsBackToLegacyDate() {
        let legacyDate = makeUTCDate(year: 2026, month: 2, day: 10, hour: 18)

        let invalidResolved = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: "invalid",
            legacyDate: legacyDate
        )
        let nilResolved = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: nil,
            legacyDate: legacyDate
        )

        #expect(invalidResolved.rawValue == "2026-02-11")
        #expect(nilResolved.rawValue == "2026-02-11")
    }

    @Test("raw key 배열이 섞여 있으면 valid는 유지하고 invalid는 동일 인덱스 legacy로 보정한다")
    func resolveDateKeys_mixedInputPreservesExistingRule() {
        let legacyDates = [
            makeUTCDate(year: 2026, month: 2, day: 10, hour: 18),
            makeUTCDate(year: 2026, month: 2, day: 20, hour: 16),
        ]

        let resolved = SettingsDateKeyPolicy.resolveDateKeys(
            rawKeys: ["2026-03-01", "invalid", "2026-03-03"],
            legacyDates: legacyDates
        )

        #expect(resolved.map(\.rawValue) == ["2026-03-01", "2026-02-21", "2026-03-03"])
    }

    @Test("raw key 배열이 nil 또는 비어있으면 legacy date 전체를 fallback한다")
    func resolveDateKeys_fallsBackWhenRawKeysMissing() {
        let legacyDates = [
            makeUTCDate(year: 2026, month: 2, day: 10, hour: 18),
            makeUTCDate(year: 2026, month: 2, day: 20, hour: 16),
        ]

        let nilResolved = SettingsDateKeyPolicy.resolveDateKeys(rawKeys: nil, legacyDates: legacyDates)
        let emptyResolved = SettingsDateKeyPolicy.resolveDateKeys(rawKeys: [], legacyDates: legacyDates)

        #expect(nilResolved.map(\.rawValue) == ["2026-02-11", "2026-02-21"])
        #expect(emptyResolved.map(\.rawValue) == ["2026-02-11", "2026-02-21"])
    }
}
