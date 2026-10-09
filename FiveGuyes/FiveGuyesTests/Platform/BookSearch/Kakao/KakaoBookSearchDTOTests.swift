//
//  KakaoBookSearchDTOTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-09.
//

@testable import FiveGuyes
import Testing

// Calendar·TimeZone을 쓰지 않는다. 기기 시간대와 무관함의 증명이다.
@Suite("KakaoBookSearchDTO 출간일 파싱 테스트")
struct KakaoBookSearchDTOTests {
    private func parse(_ datetime: String?) -> PublicationDate? {
        KakaoBookSearchDTO(
            title: "t",
            authors: nil,
            publisher: nil,
            datetime: datetime,
            isbn: nil,
            thumbnail: nil
        ).parsePublishedDate()
    }

    @Test("A4: 앞 yyyy-MM-dd를 연·월·일로 읽는다")
    func kakaoDate_a4_isoDatetime_parsesCalendarDate() {
        #expect(parse("2021-01-01T00:00:00.000+09:00") == PublicationDate(year: 2021, month: 1, day: 1))
        #expect(parse("2014-11-17T00:00:00.000+09:00") == PublicationDate(year: 2014, month: 11, day: 17))
    }

    @Test("A4: 오프셋이 달라도 앞 10자리를 그대로 읽는다")
    func kakaoDate_a4_anyOffset_keepsDatePart() {
        #expect(parse("2021-01-01T00:00:00.000Z") == PublicationDate(year: 2021, month: 1, day: 1))
        #expect(parse("2021-01-01T00:00:00.000-05:00") == PublicationDate(year: 2021, month: 1, day: 1))
    }

    @Test("A5: 형식이 다르면 nil이다")
    func kakaoDate_a5_invalidFormat_returnsNil() {
        #expect(parse(nil) == nil)
        #expect(parse("") == nil)
        #expect(parse("2021-1-1") == nil)
        #expect(parse("20210101") == nil)
        #expect(parse("abcd-ef-gh") == nil)
        #expect(parse("not a date") == nil)
        #expect(parse("2021-13-01T00:00:00.000+09:00") == nil)
    }
}
