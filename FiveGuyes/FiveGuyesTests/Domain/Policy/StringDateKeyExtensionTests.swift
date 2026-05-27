//
//  StringDateKeyExtensionTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/15/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("String/Date 키 확장 테스트")
struct StringDateKeyExtensionTests {
    @Test("extractYear는 yyyy-MM-dd 문자열에서 연도를 추출한다")
    func extractYear_returnsYear() {
        #expect("2026-02-15".extractYear() == "2026")
    }

    @Test("extractYear는 날짜 파싱 실패 시 원문을 그대로 반환한다")
    func extractYear_returnsOriginalWhenInvalid() {
        #expect("2026/02/15".extractYear() == "2026/02/15")
        #expect("invalid".extractYear() == "invalid")
    }

    @Test("String.toReadingDateKey와 Date.readingDateKey는 동일 키로 라운드트립된다")
    func stringToReadingDateKey_roundTripWithReadingDateKey() {
        let original = "2026-02-15"
        let parsedDate = original.toReadingDateKey()?.toDate(calendar: .app)
        let roundTrip = parsedDate?.readingDateKey.rawValue

        #expect(roundTrip == original)
    }

    @Test("Date.readingDateKey는 yyyy-MM-dd 형식 키를 생성한다")
    func dateReadingDateKey_matchesExpectedFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 15
        components.hour = 9
        components.minute = 30
        components.timeZone = Calendar.app.timeZone

        guard let date = Calendar.app.date(from: components) else {
            Issue.record("Invalid date fixture")
            return
        }

        #expect(date.readingDateKey.rawValue == "2026-02-15")
    }
}
