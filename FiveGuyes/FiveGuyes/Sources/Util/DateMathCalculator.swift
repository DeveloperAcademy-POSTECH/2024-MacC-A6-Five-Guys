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
        case invalidDateOrder    // startDate > endDate인 경우
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
        // 날짜 정규화: 시간 정보를 제거하고 날짜만 비교
        let normalizedStart = startDate.onlyDate
        let normalizedEnd = endDate.onlyDate

        // 날짜 순서 검증
        guard normalizedStart <= normalizedEnd else {
            throw MathError.invalidDateOrder
        }

        // Calendar.app을 사용하여 날짜 차이 계산
        let gap = Calendar.app.getDaysBetween(from: normalizedStart, to: normalizedEnd)

        // 양 끝 날짜 포함 (inclusive): gap이 0이면 같은 날 → 1일
        return gap + 1
    }

    /// 시작~종료 날짜 사이에서 제외일을 제외한 유효 일수를 계산합니다.
    ///
    /// **내부 동작:**
    /// 1. daysBetween으로 전체 일수 계산
    /// 2. excludedDates를 Set으로 변환하여 중복 제거
    /// 3. 구간 [startDate.onlyDate, endDate.onlyDate] 안에 포함된 제외일만 필터링
    /// 4. totalDays - excludedDaysCount 반환
    ///
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
        // 1. 전체 일수 계산
        let totalDays = try daysBetween(from: startDate, to: endDate)

        // 2. 날짜 정규화
        let normalizedStart = startDate.onlyDate
        let normalizedEnd = endDate.onlyDate

        // 3. 제외일 중복 제거 및 정규화
        let normalizedExcludedDates = Set(excludedDates.map { $0.onlyDate })

        // 4. 구간 [startDate, endDate] 안에 포함된 제외일만 필터링
        let excludedDaysCount = normalizedExcludedDates.filter { excludedDate in
            excludedDate >= normalizedStart && excludedDate <= normalizedEnd
        }.count

        // 5. 유효 일수 = 전체 일수 - 제외일 수
        return totalDays - excludedDaysCount
    }
}
