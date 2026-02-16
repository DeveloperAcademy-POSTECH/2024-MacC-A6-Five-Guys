//
//  ReadingDateKeyTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("ReadingDateKey 테스트")
struct ReadingDateKeyTests {
    @Test("ReadingDateKey는 Calendar.app 타임존 기준으로 키를 생성한다")
    func createsKeyUsingAppTimeZone() {
        var utcCalendar = Calendar(identifier: .gregorian)
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else {
            Issue.record("Invalid UTC time zone fixture")
            return
        }
        utcCalendar.timeZone = utcTimeZone

        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 14
        components.hour = 15
        components.minute = 30

        guard let utcDate = utcCalendar.date(from: components) else {
            Issue.record("Invalid UTC date fixture")
            return
        }

        let key = ReadingDateKey(date: utcDate)

        #expect(key.rawValue == "2026-02-15")
    }

    @Test("ReadingDateKey 파싱은 yyyy-MM-dd 정규 포맷만 허용한다")
    func parsingRejectsNonNormalizedFormat() {
        let normalized = ReadingDateKey(parsing: "2026-02-05")
        let nonNormalized = ReadingDateKey(parsing: "2026-2-5")

        #expect(normalized != nil)
        #expect(nonNormalized == nil)
    }

    @Test("ReadingDateKey toDate는 동일 키로 라운드트립된다")
    func roundTripDateConversion() {
        let key = ReadingDateKey(rawValue: "2026-02-14")
        let parsedDate = key.toDate()
        let roundTripKey = parsedDate?.readingDateKey

        #expect(roundTripKey == key)
    }

    @Test("ReadingDateKey 비교는 날짜 순서를 보장한다")
    func supportsComparableOrdering() {
        let earlier = ReadingDateKey(rawValue: "2026-02-14")
        let later = ReadingDateKey(rawValue: "2026-02-15")

        #expect(earlier < later)
    }

    @Test("fromStoredKey는 비정상 키도 드롭하지 않고 보존한다")
    func fromStoredKey_preservesInvalidRawKey() {
        let invalid = ReadingDateKey.fromStoredKey("legacy/invalid-key")
        #expect(invalid.rawValue == "legacy/invalid-key")
    }
}
