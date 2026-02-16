//
//  DateMathCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-10-24.
//

import Foundation

/// 날짜 및 일수 계산을 담당하는 Pure Function 수학 유틸리티
struct DateMathCalculator {

    // MARK: - Error Types

    enum MathError: Error {
        case invalidDateOrder
    }

    // MARK: - Public Methods

    /// 두 날짜 사이의 일수를 계산합니다 (양 끝 날짜 포함).
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 양 끝 날짜를 포함한 일수 (1 이상)
    /// - Throws:
    ///   - `MathError.invalidDateOrder`: startDate가 endDate보다 미래인 경우
    func daysBetween(from startDate: Date, to endDate: Date) throws -> Int {
        let normalizedStart = startDate.onlyDate
        let normalizedEnd = endDate.onlyDate

        guard normalizedStart <= normalizedEnd else {
            throw MathError.invalidDateOrder
        }

        let gap = Calendar.app.getDaysBetween(from: normalizedStart, to: normalizedEnd)

        return gap + 1
    }

    /// 시작~종료 날짜 사이에서 제외일을 제외한 유효 일수를 계산합니다.
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - excludedDates: 제외할 날짜 목록 (중복 가능, 구간 밖 포함 가능)
    /// - Returns: 유효 일수 (0 이상)
    /// - Throws:
    ///   - `MathError.invalidDateOrder`: startDate가 endDate보다 미래인 경우
    func validDays(
        from startDate: Date,
        to endDate: Date,
        excluding excludedDates: [Date]
    ) throws -> Int {
        let totalDays = try daysBetween(from: startDate, to: endDate)

        let normalizedStart = startDate.onlyDate
        let normalizedEnd = endDate.onlyDate

        let normalizedExcludedDates = Set(excludedDates.map { $0.onlyDate })

        let excludedDaysCount = normalizedExcludedDates.filter { excludedDate in
            excludedDate >= normalizedStart && excludedDate <= normalizedEnd
        }.count

        return totalDays - excludedDaysCount
    }
}
