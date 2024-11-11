//
//  Date+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/9/24.
//

import Foundation

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    /// 지정된 일 수만큼 UTC 기준으로 날짜를 추가합니다.
    /// - Parameter days: 추가할 일 수 (음수일 경우 감소)
    /// - Returns: UTC 기준으로 일 수가 추가된 새로운 `Date`
    func addDaysInUTC(_ days: Int) -> Date {
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC 시간대 설정
        return utcCalendar.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// 지정된 일 수만큼 날짜를 추가합니다.
    /// - Parameter days: 추가할 일 수 (음수일 경우 감소)
    /// - Returns: 일 수가 추가된 새로운 `Date`
    func addDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// `yyyy년 MM월 dd일` 형식으로 변환하여 문자열로 반환합니다.
    func toKoreanDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: self)
    }
    
    /// `yyyy년 MM월 dd일` 형식으로 변환하여 문자열로 반환합니다.
    func toKoreanDateStringWithoutYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일"
        return formatter.string(from: self)
    }

}
