//
//  ReadingPagesCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 12/26/24.
//

import Foundation

struct ReadingPagesCalculator {
    /// 페이지 계산 중 발생할 수 있는 오류
    enum CalculationError: Error {
        case divisionByZero
    }
    
    /// 읽어야 할 페이지의 차이를 계산하는 함수
    /// - Parameters:
    ///   - startPage: 시작 페이지
    ///   - endPage: 종료 페이지
    /// - Returns: 페이지 차이
    func calculatePagesBetween(endPage: Int, startPage: Int) -> Int {
        return endPage - startPage + 1
    }
    
    /// 전체 페이지 수를 전체 일수로 나누어 하루에 할당할 페이지 수를 계산하는 함수
    /// - Parameters:
    ///   - totalPages: 전체 남은 페이지 수
    ///   - totalDays: 전체 남은 일수
    /// - Returns: 하루에 읽어야 할 페이지 수 (정수 나눗셈 결과)
    /// - Throws: `CalculationError.divisionByZero` 전체 남은 일수가 0인 경우
    func calculatePagesPerDay(totalPages: Int, totalDays: Int) throws -> Int {
        guard totalDays > 0 else {
            throw CalculationError.divisionByZero
        }
        return totalPages / totalDays
    }
    
    /// 전체 페이지 수를 전체 일수로 나누었을 때의 나머지를 계산하는 함수
    /// - Parameters:
    ///   - totalPages: 전체 남은 페이지 수
    ///   - totalDays: 전체 남은 일수
    /// - Returns: 남은 페이지 수 (나누기 연산의 나머지)
    /// - Throws: `CalculationError.divisionByZero` 전체 남은 일수가 0인 경우
    private func calculateRemainderPages(totalPages: Int, totalDays: Int) throws -> Int {
        guard totalDays > 0 else {
            throw CalculationError.divisionByZero
        }
        return totalPages % totalDays
    }
    
    func calculatePagesPerDayAndRemainder(
        totalDays: Int,
        startPage: Int,
        endPage: Int
    ) -> (pagesPerDay: Int, remainder: Int) {
        do {
            // 총 페이지 수와 하루 할당량 계산
            let totalPages = calculatePagesBetween(endPage: endPage, startPage: startPage)
            
            let pagesPerDay = try calculatePagesPerDay(totalPages: totalPages, totalDays: totalDays)
            let remainder = try calculateRemainderPages(totalPages: totalPages, totalDays: totalDays)
            
            return (pagesPerDay, remainder)
        } catch {
            fatalError("calculatePagesPerDayAndRemainder: \(error.localizedDescription)")
        }
    }
}
