//
//  PageMathCalculatorTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2025-10-24.
//

@testable import FiveGuyes
import Testing

/// PageMathCalculator에 대한 Swift Testing 기반 테스트
@Suite("PageMathCalculator 테스트")
struct PageMathCalculatorTests {

    let calculator = PageMathCalculator()

    // MARK: - pagesBetween Tests

    /// 정상 케이스: 다양한 페이지 범위 계산
    @Test("pagesBetween 정상 케이스",
          arguments: [
        (1, 10, 10, "1페이지부터 10페이지까지는 총 10페이지"),
        (5, 5, 1, "같은 페이지는 1페이지로 계산"),
        (1, 300, 300, "큰 범위도 정확히 계산"),
        (50, 100, 51, "50페이지부터 100페이지까지는 51페이지")
    ])
    func pagesBetween_validCases(
        startPage: Int,
        endPage: Int,
        expected: Int,
        description: String
    ) throws {
        let result = try calculator.pagesBetween(from: startPage, to: endPage)
        #expect(result == expected, "\(description)")
    }

    /// 에러 케이스: 잘못된 페이지 범위
    @Test("pagesBetween - invalidPageRange 에러")
    func pagesBetween_invalidRange_throws() {
        #expect(throws: PageMathCalculator.MathError.invalidPageRange) {
            try calculator.pagesBetween(from: 10, to: 1)
        }
    }

    /// 에러 케이스: 음수 또는 0 페이지 번호
    @Test("pagesBetween - invalidPageNumber 에러",
          arguments: [
        (-1, 10, "음수 startPage"),
        (1, -5, "음수 endPage"),
        (0, 10, "0 startPage"),
        (1, 0, "0 endPage")
    ])
    func pagesBetween_invalidPageNumber_throws(
        startPage: Int,
        endPage: Int,
        description: String
    ) {
        #expect(throws: PageMathCalculator.MathError.invalidPageNumber, "\(description)") {
            try calculator.pagesBetween(from: startPage, to: endPage)
        }
    }

    // MARK: - pagesPerDay Tests

    /// 정상 케이스: 하루 읽을 페이지 수 계산
    @Test("pagesPerDay 정상 케이스",
          arguments: [
        (100, 10, 10, "100페이지를 10일에 나누면 10페이지/일"),
        (10, 3, 3, "10페이지를 3일에 나누면 3페이지/일 (나머지 무시)"),
        (0, 5, 0, "0페이지는 항상 0페이지/일"),
        (100, 1, 100, "1일이면 전체 페이지를 읽어야 함")
    ])
    func pagesPerDay_validCases(
        totalPages: Int,
        totalDays: Int,
        expected: Int,
        description: String
    ) throws {
        let result = try calculator.pagesPerDay(totalPages: totalPages, totalDays: totalDays)
        #expect(result == expected, "\(description)")
    }

    /// 에러 케이스: 0일 또는 음수 일수
    @Test("pagesPerDay - divisionByZero 에러",
          arguments: [
        (100, 0, "0일로 나누기"),
        (100, -5, "음수 일수")
    ])
    func pagesPerDay_divisionByZero_throws(
        totalPages: Int,
        totalDays: Int,
        description: String
    ) {
        #expect(throws: PageMathCalculator.MathError.divisionByZero, "\(description)") {
            try calculator.pagesPerDay(totalPages: totalPages, totalDays: totalDays)
        }
    }

    // MARK: - remainderPages Tests

    /// 정상 케이스: 나머지 페이지 계산
    @Test("remainderPages 정상 케이스",
          arguments: [
        (100, 10, 0, "나머지 없음"),
        (10, 3, 1, "10 % 3 = 1"),
        (0, 5, 0, "0페이지의 나머지는 0")
    ])
    func remainderPages_validCases(
        totalPages: Int,
        totalDays: Int,
        expected: Int,
        description: String
    ) throws {
        let result = try calculator.remainderPages(totalPages: totalPages, totalDays: totalDays)
        #expect(result == expected, "\(description)")
    }

    /// 에러 케이스: 0일로 나머지 계산
    @Test("remainderPages - divisionByZero 에러")
    func remainderPages_divisionByZero_throws() {
        #expect(throws: PageMathCalculator.MathError.divisionByZero) {
            try calculator.remainderPages(totalPages: 100, totalDays: 0)
        }
    }

    // MARK: - dividePages Tests

    /// 정상 케이스: 하루 페이지 수와 나머지를 함께 계산
    @Test("dividePages 정상 케이스")
    func dividePages_validCases() throws {
        // 케이스 1: 나머지 없음
        let result1 = try calculator.dividePages(from: 1, to: 100, over: 10)
        #expect(result1.daily == 10, "100페이지를 10일에 나누면 10페이지/일")
        #expect(result1.remainder == 0, "나머지는 0")

        // 케이스 2: 나머지 있음
        let result2 = try calculator.dividePages(from: 1, to: 10, over: 3)
        #expect(result2.daily == 3, "10페이지를 3일에 나누면 3페이지/일")
        #expect(result2.remainder == 1, "나머지는 1")

        // 케이스 3: 단일 페이지, 1일
        let result3 = try calculator.dividePages(from: 5, to: 5, over: 1)
        #expect(result3.daily == 1)
        #expect(result3.remainder == 0)

        // 케이스 4: 큰 나머지
        let result4 = try calculator.dividePages(from: 1, to: 100, over: 7)
        #expect(result4.daily == 14, "100 ÷ 7 = 14")
        #expect(result4.remainder == 2, "100 % 7 = 2")
    }

    /// 에러 케이스: divisionByZero
    @Test("dividePages - divisionByZero 에러")
    func dividePages_divisionByZero_throws() {
        #expect(throws: PageMathCalculator.MathError.divisionByZero) {
            try calculator.dividePages(from: 1, to: 100, over: 0)
        }
    }

    /// 에러 케이스: invalidPageRange
    @Test("dividePages - invalidPageRange 에러")
    func dividePages_invalidRange_throws() {
        #expect(throws: PageMathCalculator.MathError.invalidPageRange) {
            try calculator.dividePages(from: 100, to: 1, over: 5)
        }
    }

    /// 에러 케이스: invalidPageNumber
    @Test("dividePages - invalidPageNumber 에러")
    func dividePages_invalidPageNumber_throws() {
        #expect(throws: PageMathCalculator.MathError.invalidPageNumber) {
            try calculator.dividePages(from: -1, to: 100, over: 5)
        }
    }
}
