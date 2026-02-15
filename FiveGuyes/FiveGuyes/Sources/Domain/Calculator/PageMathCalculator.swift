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
        case divisionByZero
        case invalidPageRange
        case invalidPageNumber
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
        guard startPage >= 1 else {
            throw MathError.invalidPageNumber
        }

        guard endPage >= 1 else {
            throw MathError.invalidPageNumber
        }

        guard startPage <= endPage else {
            throw MathError.invalidPageRange
        }

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
        let totalPages = try pagesBetween(from: startPage, to: endPage)

        let daily = try pagesPerDay(totalPages: totalPages, totalDays: days)

        let remainder = try remainderPages(totalPages: totalPages, totalDays: days)

        return (daily, remainder)
    }
}
