//
//  Calendar+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/21/24.
//

import Foundation

extension Calendar {
    /// -4시간 기준으로 조정된 요일 인덱스 (0: 일요일, 6: 토요일)
    func getAdjustedWeekdayIndex(from date: Date, hourOffset: Int = -4) -> Int {
        // 날짜를 -4시간 조정
        let adjustedDate = date.adjustedDate(hourOffset: hourOffset)
        // 요일 계산 (0: 일요일 ~ 6: 토요일)
        return self.component(.weekday, from: adjustedDate) - 1
    }
}
