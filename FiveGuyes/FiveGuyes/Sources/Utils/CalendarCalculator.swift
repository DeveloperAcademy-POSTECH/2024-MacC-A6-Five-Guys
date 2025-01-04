//
//  CalendarManager.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/2/25.
//

import Foundation

struct CalendarCalculator {
    let calendar = Calendar.current
    
    /// 주어진 날짜가 속한 월의 첫 번째 날짜를 반환합니다.
    /// - Parameter month: 기준이 되는 날짜.
    /// - Returns: 해당 월의 첫 번째 날짜.
    func startDateOfMonth(_ month: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: components)!
    }
    
    /// 주어진 월에서 특정 일을 계산하여 반환합니다.
    /// - Parameters:
    ///   - day: 기준 월에서의 날짜 (1일부터 시작).
    ///   - month: 기준이 되는 월.
    /// - Returns: 계산된 날짜.
    func dateForDay(_ day: Int, inMonth month: Date) -> Date {
        return calendar.date(byAdding: .day, value: day, to: startDateOfMonth(month))!
    }
    
    /// 주어진 월에 포함된 날짜의 수를 반환합니다.
    /// - Parameter date: 기준이 되는 월.
    /// - Returns: 해당 월의 일 수. 계산할 수 없는 경우 0을 반환.
    func numberOfDays(in date: Date) -> Int {
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    /// 주어진 월의 첫 번째 날짜가 속한 주의 요일을 반환합니다.
    /// 요일은 1(일요일)부터 7(토요일)까지 나타냅니다.
    /// - Parameter date: 기준이 되는 월.
    /// - Returns: 해당 월 첫 번째 날짜의 요일 순서.
    func firstWeekdayOfMonth(in date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDayOfMonth = calendar.date(from: components)!
        
        return calendar.component(.weekday, from: firstDayOfMonth)
    }
    
    /// 주어진 날짜에 월 단위로 값을 추가하여 계산된 날짜를 반환합니다.
    /// - Parameters:
    ///   - monthOffset: 추가할 월의 수. 음수 값을 사용하면 이전 월을 계산.
    ///   - currentMonth: 기준이 되는 날짜.
    /// - Returns: 계산된 새로운 날짜.
    func addMonths(to currentMonth: Date, by monthOffset: Int) -> Date {
        return calendar.date(byAdding: .month, value: monthOffset, to: currentMonth)!
    }
}
