//
//  Calendar+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/21/24.
//

import Foundation

extension Calendar {
    /// 특정 날짜를 기준으로 -4시간 조정된 요일 인덱스를 반환합니다.
    /// - Parameters:
    ///   - date: 기준이 되는 날짜.
    ///   - hourOffset: 시간 오프셋. 기본값은 -4로 설정되어 있습니다.
    /// - Returns: 0(일요일)부터 6(토요일)까지의 요일 인덱스.
    /// - Note: 기본 오프셋(-4)을 사용하여 하루의 기준을 새벽 4시로 설정합니다.
    func getAdjustedWeekdayIndex(from date: Date, hourOffset: Int = -4) -> Int {
        // 날짜를 -4시간 조정
        let adjustedDate = date.adjustedDate(hourOffset: hourOffset)
        // 요일 계산 (0: 일요일 ~ 6: 토요일)
        return self.component(.weekday, from: adjustedDate) - 1
    }
    
    /// 주어진 날짜의 요일 인덱스를 반환합니다.
    /// - Parameter date: 기준이 되는 날짜.
    /// - Returns: 0(일요일)부터 6(토요일)까지의 요일 인덱스.
    func getWeekdayIndex(from date: Date) -> Int {
        return self.component(.weekday, from: date) - 1
    }
}

extension Calendar {
    /// 두 날짜 사이의 날짜 차이를 계산하고, 값이 없으면 0, 하나라도 값이 있으면 1을 반환
    func getDateGap(from: Date?, to: Date?) -> Int {
        if from == nil && to == nil {
            return 0 // 둘 다 값이 없으면 0
        } else if let from, let to {
            let fromDateOnly = from.onlyDate
            let toDateOnly = to.onlyDate
            
            // 두 날짜가 존재하면 차이를 계산
            return self.dateComponents([.day], from: fromDateOnly, to: toDateOnly).day! + 1
        } else {
            return 1 // 하나라도 값이 있으면 1
        }
    }
}
