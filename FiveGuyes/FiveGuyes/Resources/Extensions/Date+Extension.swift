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
    
    /// `MM월 dd일` 형식으로 변환하여 문자열로 반환합니다.
    func toKoreanDateStringWithoutYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일"
        return formatter.string(from: self)
    }
    
    /// `MM월 dd일` 형식으로 변환하여 문자열로 반환합니다.
    func toKoreanDateStringWithoutDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY년 M월"
        return formatter.string(from: self)
    }
}

// Date 확장으로 날짜 문자열 포맷 추가
extension Date {
    func toYearMonthDayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// 04:00 AM을 기준으로 날짜를 조정하여 "yyyy-MM-dd" 형식으로 반환
    func toAdjustedYearMonthDayString(hourOffset: Int = -4) -> String {
        let calendar = Calendar.current
        let adjustedDate = calendar.date(byAdding: .hour, value: hourOffset, to: self) ?? self
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: adjustedDate)
    }
    
    /// 기준 시각으로 조정된 날짜 반환
    func adjustedDate(hourOffset: Int = -4) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .hour, value: hourOffset, to: self) ?? self
    }
}

extension Date {
    /// 현재 날짜가 특정 시간 범위에 포함되어 있는지 확인하는 메서드
    func isInHourRange(start: Int, end: Int, calendar: Calendar = Calendar.current) -> Bool {
        let hour = calendar.component(.hour, from: self)
        return hour >= start && hour < end
    }
}


extension Date {
    /// 시간 부분을 버리기
    var onlyDate: Date {
        let component = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: component) ?? Date()
    }
}
