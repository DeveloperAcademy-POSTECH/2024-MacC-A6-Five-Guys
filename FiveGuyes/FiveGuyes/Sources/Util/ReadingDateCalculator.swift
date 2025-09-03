//
//  ReadingDateCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 12/26/24.
//

import Foundation

struct ReadingDateCalculator {
    enum DateError: Error {
        case invalidDateOrder
    }
    
    /// 시작 날짜와 마지막 날짜 사이의 일수 차이를 계산하는 메서드
    /// - Returns: 두 날짜 사이의 일수 차이 (같은 날일 경우 1을 반환)
    /// - Throws: `DateError.invalidDateOrder` 시작 날짜가 종료 날짜보다 이후인 경우
    /// - Note:
    ///   - 이 메서드에서는 도메인 로직을 통해 시작 날짜와 종료 날짜를 모두 포함하여 결과에 1을 추가합니다.
    func calculateDaysBetween(startDate: Date, endDate: Date) throws -> Int {
        // 시작 날짜가 종료 날짜 이후인 경우 에러를 던짐
        guard startDate.onlyDate <= endDate.onlyDate else {
            throw DateError.invalidDateOrder
        }

        // 시작 날짜와 종료 날짜 간의 차이 계산
        let gap = Calendar.app.getDaysBetween(from: startDate.onlyDate, to: endDate.onlyDate)
        
        // 시작 날짜와 종료 날짜를 모두 포함하기 위해 1을 추가
        return gap + 1
    }
    
    /// 시작 날짜와 마지막 날짜 사이의 유효한 일수를 계산하는 메서드
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 마지막 날짜
    ///   - excludedDates: 제외할 날짜 배열
    /// - Returns: 유효한 일수 (양쪽 날짜 포함, 제외 날짜는 제외)
    /// - Throws: `DateError.invalidDateOrder` 시작 날짜가 종료 날짜보다 이후인 경우
    func calculateValidReadingDays(
        startDate: Date,
        endDate: Date,
        excludedDates: [Date]
    ) throws -> Int {
        
        // 두 날짜 사이의 총 일수를 계산 (양쪽 날짜 포함)
        let totalDays = try calculateDaysBetween(startDate: startDate, endDate: endDate)
        
        // 제외된 날짜 중 시작 날짜와 마지막 날짜 사이에 포함된 날짜 수를 계산
        let (start, end) = (startDate.onlyDate, endDate.onlyDate)
        
        let excludedDaysCount = excludedDates.filter {
            let excludedDate = $0.onlyDate
            return excludedDate >= start && excludedDate <= end
        }.count
        
        // 유효한 날짜 수 = 총 일수 - 제외된 날짜 수
        return totalDays - excludedDaysCount
    }
}
