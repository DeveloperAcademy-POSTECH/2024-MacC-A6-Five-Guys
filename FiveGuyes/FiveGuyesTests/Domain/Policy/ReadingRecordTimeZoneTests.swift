//
//  ReadingRecordTimeZoneTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/17/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("ReadingRecord 타임존 호환성 테스트")
struct ReadingRecordTimeZoneTests {
    @Test("legacy 데이터 디코딩 시 timeZoneID 기본값을 사용한다")
    func decodeLegacyRecordUsesDefaultTimeZone() throws {
        let data = try #require("""
            {"targetPages":120,"pagesRead":90}
            """.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ReadingRecord.self, from: data)

        #expect(decoded.targetPages == 120)
        #expect(decoded.pagesRead == 90)
        #expect(decoded.timeZoneID == ReadingRecord.legacyDefaultTimeZoneID)
    }

    @Test("timeZoneID가 비어 있으면 기본값으로 정규화한다")
    func decodeBlankTimeZoneUsesDefault() throws {
        let data = try #require("""
            {"targetPages":120,"pagesRead":90,"timeZoneID":"  "}
            """.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ReadingRecord.self, from: data)

        #expect(decoded.timeZoneID == ReadingRecord.legacyDefaultTimeZoneID)
    }

    @Test("명시된 timeZoneID는 유지한다")
    func decodeKeepsProvidedTimeZoneID() throws {
        let data = try #require("""
            {"targetPages":120,"pagesRead":90,"timeZoneID":"America/Los_Angeles"}
            """.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ReadingRecord.self, from: data)

        #expect(decoded.timeZoneID == "America/Los_Angeles")
    }

    @Test("공용 정규화 함수는 공백 입력을 legacy 기본값으로 정규화한다")
    func normalizedTimeZoneID_blankInputUsesLegacyDefault() {
        let normalized = ReadingRecord.normalizedTimeZoneID("   ")
        #expect(normalized == ReadingRecord.legacyDefaultTimeZoneID)
    }

    @Test("공용 병합 함수는 lhs가 legacy이고 rhs가 비-legacy면 rhs를 우선한다")
    func mergedTimeZoneID_prefersNonLegacyWhenLhsIsLegacy() {
        let merged = ReadingRecord.mergedTimeZoneID(
            lhs: ReadingRecord.legacyDefaultTimeZoneID,
            rhs: "America/Los_Angeles"
        )
        #expect(merged == "America/Los_Angeles")
    }

    @Test("공용 병합 함수는 lhs가 비-legacy면 lhs를 유지한다")
    func mergedTimeZoneID_keepsLhsWhenLhsIsNonLegacy() {
        let merged = ReadingRecord.mergedTimeZoneID(
            lhs: "Europe/London",
            rhs: "America/Los_Angeles"
        )
        #expect(merged == "Europe/London")
    }
}
