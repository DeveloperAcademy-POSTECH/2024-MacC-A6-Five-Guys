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
    @Test("A4·A5: 유효한 값으로 만들고 월·일은 없어도 된다")
    func publicationDate_a4_a5_validInput_created() {
        let full = PublicationDate(year: 2021, month: 1, day: 1)
        let yearOnly = PublicationDate(year: 2021)
        let yearMonth = PublicationDate(year: 2021, month: 12)

        #expect(full?.year == 2021)
        #expect(full?.month == 1)
        #expect(full?.day == 1)
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

    @Test("A5: 월 없이 일만 있으면 nil이다")
    func publicationDate_a5_dayWithoutMonth_returnsNil() {
        #expect(PublicationDate(year: 2021, month: nil, day: 5) == nil)
        #expect(PublicationDate(year: 2021, month: 4, day: nil) != nil)
    }

    @Test("A5: 달력에 없는 날짜면 nil이다")
    func publicationDate_a5_nonexistentDate_returnsNil() {
        #expect(PublicationDate(year: 2021, month: 2, day: 31) == nil)
        #expect(PublicationDate(year: 2021, month: 2, day: 29) == nil)
        #expect(PublicationDate(year: 2020, month: 2, day: 29) != nil)
    }
}
