//
//  PageMathCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-10-24.
//

import Foundation

/// 페이지 수 계산을 담당하는 Pure Function 수학 유틸리티
struct PageMathCalculator {

    // MARK: - Error Types

    enum MathError: Error {
        case divisionByZero           // totalDays가 0 이하인 경우
        case invalidPageRange         // startPage > endPage인 경우
        case invalidPageNumber        // 페이지 번호가 음수이거나 0인 경우
    }

    // MARK: - Public Methods

    /// 시작 페이지와 종료 페이지 사이의 총 페이지 수를 계산합니다.
    ///
    /// - Parameters:
    ///   - startPage: 시작 페이지 번호 (1 이상)
    ///   - endPage: 종료 페이지 번호 (1 이상)
    /// - Returns: 총 페이지 수 (양수)
    /// - Throws:
    ///   - `MathError.invalidPageNumber`: 페이지 번호가 1보다 작은 경우
    ///   - `MathError.invalidPageRange`: startPage가 endPage보다 큰 경우
    func pagesBetween(from startPage: Int, to endPage: Int) throws -> Int {
        // 페이지 번호 유효성 검증 (1 이상)
        guard startPage >= 1 else {
            throw MathError.invalidPageNumber
        }

        guard endPage >= 1 else {
            throw MathError.invalidPageNumber
        }

        // 페이지 범위 유효성 검증
        guard startPage <= endPage else {
            throw MathError.invalidPageRange
        }

        // 양 끝 페이지 포함하여 계산
        return endPage - startPage + 1
    }

    /// 전체 페이지 수를 전체 일수로 나누어 하루에 읽을 페이지 수를 계산합니다.
    ///
    /// - Parameters:
    ///   - totalPages: 전체 페이지 수 (0 이상)
    ///   - totalDays: 전체 일수 (1 이상)
    /// - Returns: 하루에 읽을 페이지 수 (정수 나눗셈 결과)
    /// - Throws:
    ///   - `MathError.divisionByZero`: totalDays가 0 이하인 경우
    func pagesPerDay(totalPages: Int, totalDays: Int) throws -> Int {
        guard totalDays > 0 else {
            throw MathError.divisionByZero
        }

        return totalPages / totalDays
    }

    /// 전체 페이지 수를 전체 일수로 나눈 나머지를 계산합니다.
    ///
    /// - Parameters:
    ///   - totalPages: 전체 페이지 수 (0 이상)
    ///   - totalDays: 전체 일수 (1 이상)
    /// - Returns: 나머지 페이지 수
    /// - Throws:
    ///   - `MathError.divisionByZero`: totalDays가 0 이하인 경우
    func remainderPages(totalPages: Int, totalDays: Int) throws -> Int {
        guard totalDays > 0 else {
            throw MathError.divisionByZero
        }

        return totalPages % totalDays
    }

    /// 하루에 읽을 페이지 수와 나머지 페이지 수를 한 번에 계산합니다.
    ///
    /// **내부 동작:**
    /// 1. `pagesBetween`으로 총 페이지 수 계산
    /// 2. `pagesPerDay`로 일일 페이지 수 계산
    /// 3. `remainderPages`로 나머지 페이지 수 계산
    ///
    /// - Parameters:
    ///   - startPage: 시작 페이지 번호 (1 이상)
    ///   - endPage: 종료 페이지 번호 (1 이상)
    ///   - days: 전체 일수 (1 이상)
    /// - Returns: (daily: 일일 페이지 수, remainder: 나머지 페이지 수)
    /// - Throws:
    ///   - `MathError.divisionByZero`: days가 0 이하인 경우
    ///   - `MathError.invalidPageNumber`: 페이지 번호가 1보다 작은 경우
    ///   - `MathError.invalidPageRange`: startPage가 endPage보다 큰 경우
    func dividePages(from startPage: Int, to endPage: Int, over days: Int) throws -> (daily: Int, remainder: Int) {
        // 1. 총 페이지 수 계산
        let totalPages = try pagesBetween(from: startPage, to: endPage)

        // 2. 일일 페이지 수 계산
        let daily = try pagesPerDay(totalPages: totalPages, totalDays: days)

        // 3. 나머지 페이지 수 계산
        let remainder = try remainderPages(totalPages: totalPages, totalDays: days)

        return (daily, remainder)
    }
}
