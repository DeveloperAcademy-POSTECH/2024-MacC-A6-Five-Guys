//
//  KakaoBookSearchDTOTests.swift
//  FiveGuyesTests
//
//  Created by Claude on 2026-10-09.
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
        ).toBookSearchItem().publishedDate
    }

    @Test("A5: 앞 yyyy-MM-dd를 연·월·일로 읽는다")
    func kakaoDate_a5_isoDatetime_parsesCalendarDate() {
        #expect(parse("2021-01-01T00:00:00.000+09:00") == PublicationDate(year: 2021, month: 1, day: 1))
        #expect(parse("2014-11-17T00:00:00.000+09:00") == PublicationDate(year: 2014, month: 11, day: 17))
    }

    @Test("A5: 오프셋이 달라도 앞 10자리를 그대로 읽는다")
    func kakaoDate_a5_anyOffset_keepsDatePart() {
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
        #expect(parse("+021-01-01T00:00:00.000+09:00") == nil)
        #expect(parse("2021-+1-01T00:00:00.000+09:00") == nil)
        #expect(parse("2021-13-01T00:00:00.000+09:00") == nil)
    }

    private func cover(_ thumbnail: String?) -> String? {
        KakaoBookSearchDTO(
            title: "t",
            authors: nil,
            publisher: nil,
            datetime: nil,
            isbn: nil,
            thumbnail: thumbnail
        ).toBookSearchItem().coverImageURL
    }

    @Test("A4: 썸네일의 fname 원본 주소를 https로 쓴다")
    func kakaoCover_a4_fname_usesOriginalOverHTTPS() {
        let thumbnail = "https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=http%3A%2F%2Ft1.daumcdn.net%2Flbook%2Fimage%2F123%3Ftimestamp%3D20210101"
        #expect(cover(thumbnail) == "https://t1.daumcdn.net/lbook/image/123?timestamp=20210101")
    }

    @Test("A4: fname이 없으면 썸네일 그대로다")
    func kakaoCover_a4_noFname_keepsThumbnail() {
        #expect(cover("https://example.com/cover.jpg") == "https://example.com/cover.jpg")
    }

    @Test("A4: fname이 URL이 아니면 썸네일 그대로다")
    func kakaoCover_a4_invalidFname_keepsThumbnail() {
        let notURL = "https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=not%20a%20url"
        let badScheme = "https://search1.kakaocdn.net/thumb/R120x174.q85/?fname=ftp%3A%2F%2Fexample.com%2Fa.jpg"
        #expect(cover(notURL) == notURL)
        #expect(cover(badScheme) == badScheme)
    }

    @Test("A4: 썸네일이 비었거나 없으면 nil이다")
    func kakaoCover_a4_emptyThumbnail_returnsNil() {
        #expect(cover("") == nil)
        #expect(cover(nil) == nil)
    }

    private func isbn13(_ isbn: String?) -> String? {
        KakaoBookSearchDTO(
            title: "t",
            authors: nil,
            publisher: nil,
            datetime: nil,
            isbn: isbn,
            thumbnail: nil
        ).toBookSearchItem().isbn13
    }

    @Test("A11: 978·979로 시작하는 13자리만 ISBN-13이다")
    func kakaoISBN_a11_prefix_acceptsOnly978And979() {
        #expect(isbn13("8936434128 9788936434120") == "9788936434120")
        #expect(isbn13("9791190000000") == "9791190000000")
        #expect(isbn13("2090000157222") == nil)
        #expect(isbn13("1234567890") == nil)
    }
}
