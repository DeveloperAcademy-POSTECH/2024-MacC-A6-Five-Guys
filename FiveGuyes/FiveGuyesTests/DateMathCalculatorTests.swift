//
//  DateMathCalculatorTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2025-10-24.
//

@testable import FiveGuyes
import Foundation
import Testing

/// DateMathCalculator에 대한 Swift Testing 기반 테스트
@Suite("DateMathCalculator 테스트")
struct DateMathCalculatorTests {

    let calculator = DateMathCalculator()

    // MARK: - Helper Methods

    /// 테스트용 날짜 생성 헬퍼 (yyyy-MM-dd 형식)
    private func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }

    // MARK: - daysBetween Tests

    /// 정상 케이스: 다양한 날짜 범위 계산
    @Test("daysBetween 정상 케이스",
          arguments: [
        ("2024-01-01", "2024-01-01", 1, "같은 날짜는 1일"),
        ("2024-01-01", "2024-01-02", 2, "연속된 2일"),
        ("2024-01-01", "2024-01-07", 7, "일주일"),
        ("2024-01-01", "2024-01-31", 31, "한 달 (1월)"),
        ("2024-01-25", "2024-02-05", 12, "월을 넘어가는 경우"),
        ("2024-12-28", "2025-01-03", 7, "연도를 넘어가는 경우")
    ])
    func daysBetween_validCases(
        startDateString: String,
        endDateString: String,
        expected: Int,
        description: String
    ) throws {
        let startDate = makeDate(startDateString)
        let endDate = makeDate(endDateString)

        let result = try calculator.daysBetween(from: startDate, to: endDate)
        #expect(result == expected, "\(description)")
    }

    /// 에러 케이스: 잘못된 날짜 순서
    @Test("daysBetween - invalidDateOrder 에러")
    func daysBetween_invalidOrder_throws() {
        let startDate = makeDate("2024-01-10")
        let endDate = makeDate("2024-01-01")

        #expect(throws: DateMathCalculator.MathError.invalidDateOrder) {
            try calculator.daysBetween(from: startDate, to: endDate)
        }
    }

    /// 시간 정보가 포함된 날짜도 정규화되어 정상 작동
    @Test("daysBetween - 시간 정보 정규화")
    func daysBetween_withTimeComponents_normalized() throws {
        let calendar = Calendar.app

        guard let startDate = calendar.date(from: DateComponents(
            year: 2024, month: 1, day: 1, hour: 14, minute: 30
        )) else {
            Issue.record("날짜 생성 실패")
            return
        }

        guard let endDate = calendar.date(from: DateComponents(
            year: 2024, month: 1, day: 3, hour: 9, minute: 15
        )) else {
            Issue.record("날짜 생성 실패")
            return
        }

        let result = try calculator.daysBetween(from: startDate, to: endDate)
        #expect(result == 3, "시간 정보는 무시되고 날짜만으로 3일로 계산")
    }

    // MARK: - validDays Tests

    /// 제외일이 없는 케이스
    @Test("validDays - 제외일 없음")
    func validDays_withoutExcludedDates() throws {
        let startDate = makeDate("2024-01-01")
        let endDate = makeDate("2024-01-10")

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: []
        )

        #expect(result == 10, "제외일이 없으면 전체 일수와 동일")
    }

    /// 구간 내 제외일이 있는 케이스
    @Test("validDays - 구간 내 제외일")
    func validDays_withExcludedDates_insideRange() throws {
        let startDate = makeDate("2024-01-01")
        let endDate = makeDate("2024-01-10")

        let excludedDates = [
            makeDate("2024-01-03"),
            makeDate("2024-01-05"),
            makeDate("2024-01-07")
        ]

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: excludedDates
        )

        #expect(result == 7, "10일 중 3일을 제외하면 7일")
    }

    /// 구간 밖 제외일은 무시되는 케이스
    @Test("validDays - 구간 밖 제외일 무시")
    func validDays_excludedDates_outsideRange_ignored() throws {
        let startDate = makeDate("2024-01-05")
        let endDate = makeDate("2024-01-10")

        let excludedDates = [
            makeDate("2024-01-01"),  // 구간 이전
            makeDate("2024-01-02"),  // 구간 이전
            makeDate("2024-01-15")   // 구간 이후
        ]

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: excludedDates
        )

        #expect(result == 6, "구간 밖 제외일은 무시되고 전체 6일이 유효")
    }

    /// 구간 내외 제외일이 혼합된 케이스
    @Test("validDays - 혼합된 제외일")
    func validDays_mixedExcludedDates() throws {
        let startDate = makeDate("2024-01-05")
        let endDate = makeDate("2024-01-10")

        let excludedDates = [
            makeDate("2024-01-01"),  // 구간 밖 (무시)
            makeDate("2024-01-06"),  // 구간 내 (카운트)
            makeDate("2024-01-08"),  // 구간 내 (카운트)
            makeDate("2024-01-15")   // 구간 밖 (무시)
        ]

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: excludedDates
        )

        #expect(result == 4, "6일 중 2일(6일, 8일)을 제외하면 4일")
    }

    /// 중복된 제외일이 자동으로 필터링되는 케이스
    @Test("validDays - 중복 제외일 필터링")
    func validDays_duplicateExcludedDates_filtered() throws {
        let startDate = makeDate("2024-01-01")
        let endDate = makeDate("2024-01-10")

        let excludedDates = [
            makeDate("2024-01-03"),
            makeDate("2024-01-03"),  // 중복
            makeDate("2024-01-05"),
            makeDate("2024-01-05"),  // 중복
            makeDate("2024-01-05")   // 중복
        ]

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: excludedDates
        )

        #expect(result == 8, "중복 제외일은 자동 제거되어 3일, 5일만 제외되고 8일이 유효")
    }

    /// 모든 날짜가 제외일인 케이스 → 0일
    @Test("validDays - 모든 날짜 제외")
    func validDays_allDaysExcluded_returns0() throws {
        let startDate = makeDate("2024-01-01")
        let endDate = makeDate("2024-01-03")

        let excludedDates = [
            makeDate("2024-01-01"),
            makeDate("2024-01-02"),
            makeDate("2024-01-03")
        ]

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: excludedDates
        )

        #expect(result == 0, "모든 날짜가 제외되면 유효 일수는 0일")
    }

    /// 단일 날짜 케이스
    @Test("validDays - 단일 날짜")
    func validDays_singleDay() throws {
        let date = makeDate("2024-01-01")

        // 제외일 없음
        let result1 = try calculator.validDays(
            from: date,
            to: date,
            excluding: []
        )
        #expect(result1 == 1, "단일 날짜, 제외일 없음 → 1일")

        // 제외일 포함
        let result2 = try calculator.validDays(
            from: date,
            to: date,
            excluding: [date]
        )
        #expect(result2 == 0, "단일 날짜가 제외일 → 0일")
    }

    /// 에러 케이스: 잘못된 날짜 순서
    @Test("validDays - invalidDateOrder 에러")
    func validDays_invalidDateOrder_throws() {
        let startDate = makeDate("2024-01-10")
        let endDate = makeDate("2024-01-01")

        #expect(throws: DateMathCalculator.MathError.invalidDateOrder) {
            try calculator.validDays(
                from: startDate,
                to: endDate,
                excluding: []
            )
        }
    }

    /// 시간 정보가 포함된 제외일도 정상 작동
    @Test("validDays - 제외일 시간 정보 정규화")
    func validDays_excludedDatesWithTime_normalized() throws {
        let startDate = makeDate("2024-01-01")
        let endDate = makeDate("2024-01-10")

        let calendar = Calendar.app
        guard let excludedDate1 = calendar.date(from: DateComponents(
            year: 2024, month: 1, day: 3, hour: 14, minute: 30
        )) else {
            Issue.record("날짜 생성 실패")
            return
        }

        guard let excludedDate2 = calendar.date(from: DateComponents(
            year: 2024, month: 1, day: 5, hour: 9, minute: 0
        )) else {
            Issue.record("날짜 생성 실패")
            return
        }

        let result = try calculator.validDays(
            from: startDate,
            to: endDate,
            excluding: [excludedDate1, excludedDate2]
        )

        #expect(result == 8, "시간 정보가 있어도 날짜만으로 정규화되어 2일 제외, 8일 유효")
    }
}
