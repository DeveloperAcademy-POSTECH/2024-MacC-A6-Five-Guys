//
//  Calendar+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/21/24.
//

import Foundation

extension Calendar {
    static var app: Calendar = {
        // 한국식 주 규칙으로 고정
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        calendar.firstWeekday = 1            // 일요일 시작
        calendar.minimumDaysInFirstWeek = 1  // 하루만 있어도 1주차
        return calendar
    }()
    
    /// 주어진 날짜의 요일 인덱스를 반환합니다.
    /// - Parameter date: 기준이 되는 날짜.
    /// - Returns: 0(일요일)부터 6(토요일)까지의 요일 인덱스.
    func getWeekdayIndex(from date: Date) -> Int {
        return self.component(.weekday, from: date) - 1
    }
}

// MARK: - 수정 주우웅 ❗️❗️❗️❗️❗️
extension Calendar {
    /// 두 날짜 사이의 날짜 차이 구하기
    func getDaysBetween(from: Date, to: Date) -> Int {
        self.dateComponents([.day], from: from, to: to).day ?? 0
    }
}
