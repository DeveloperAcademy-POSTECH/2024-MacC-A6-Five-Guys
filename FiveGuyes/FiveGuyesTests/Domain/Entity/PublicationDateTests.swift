//
//  PublicationDateTests.swift
//  FiveGuyesTests
//
//  Created by Claude on 2026-10-09.
//

@testable import FiveGuyes
import Testing

@Suite("PublicationDate 테스트")
struct PublicationDateTests {
    @Test("A4: 유효한 연·월·일로 만든다")
    func publicationDate_a4_validInput_created() {
        let date = PublicationDate(year: 2021, month: 1, day: 1)

        #expect(date?.year == 2021)
        #expect(date?.month == 1)
        #expect(date?.day == 1)
    }

    @Test("A5: 월·일은 없어도 된다")
    func publicationDate_a5_optionalMonthAndDay_created() {
        let yearOnly = PublicationDate(year: 2021)
        let yearMonth = PublicationDate(year: 2021, month: 12)

        #expect(yearOnly?.month == nil)
        #expect(yearOnly?.day == nil)
        #expect(yearMonth?.month == 12)
        #expect(yearMonth?.day == nil)
    }

    @Test("A5: 범위 밖 값이면 nil이다")
    func publicationDate_a5_outOfRange_returnsNil() {
        #expect(PublicationDate(year: 0) == nil)
        #expect(PublicationDate(year: -1) == nil)
        #expect(PublicationDate(year: 2021, month: 0) == nil)
        #expect(PublicationDate(year: 2021, month: 13) == nil)
        #expect(PublicationDate(year: 2021, month: 1, day: 0) == nil)
        #expect(PublicationDate(year: 2021, month: 1, day: 32) == nil)
    }
}
