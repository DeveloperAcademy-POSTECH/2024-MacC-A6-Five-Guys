//
//  ReadingDateProviding.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/14/26.
//

import Foundation

/// 독서 도메인 기준의 "오늘" 값을 제공합니다.
/// 현재 정책은 04:00 경계 보정이 적용된 날짜입니다.
protocol ReadingDateProviding {
    func today() -> Date
}

struct DefaultReadingDateProvider: ReadingDateProviding {
    private let dayBoundaryPolicy: any DayBoundaryProviding

    init(dayBoundaryPolicy: any DayBoundaryProviding = DayBoundary.shared) {
        self.dayBoundaryPolicy = dayBoundaryPolicy
    }

    func today() -> Date {
        dayBoundaryPolicy.adjustedNow()
    }
}
