//
//  DayBoundaryProviding.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/14/26.
//

import Foundation

/// 앱의 "하루 경계" 기준(현재 04:00)을 계산하는 정책 인터페이스입니다.
protocol DayBoundaryProviding {
    /// 현재 시각을 정책 기준 하루로 정규화한 값을 반환합니다.
    func adjustedNow() -> Date

    /// 전달받은 시각을 정책 기준 하루로 정규화한 값을 반환합니다.
    func adjustedDate(from date: Date) -> Date

    /// 전달받은 시각을 정책 기준 날짜 키(`yyyy-MM-dd`)로 반환합니다.
    func adjustedDayKey(from date: Date) -> String
}

/// 기본 하루 경계 정책 구현입니다.
///
/// dayStartHour = 4 라면
/// - 2026-02-14 03:59 -> 2026-02-13 키
/// - 2026-02-14 04:00 -> 2026-02-14 키
struct DefaultDayBoundaryPolicy: DayBoundaryProviding {
    private let dayStartHour: Int
    private let calendar: Calendar

    init(dayStartHour: Int = 4, calendar: Calendar = .app) {
        self.dayStartHour = dayStartHour
        self.calendar = calendar
    }

    func adjustedNow() -> Date {
        adjustedDate(from: Date())
    }

    func adjustedDate(from date: Date) -> Date {
        calendar.date(byAdding: .hour, value: -dayStartHour, to: date) ?? date
    }

    func adjustedDayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: adjustedDate(from: date))
    }
}

/// 하루 경계 정책 전역 접근 지점입니다.
enum DayBoundary {
    static let shared: any DayBoundaryProviding = DefaultDayBoundaryPolicy()
}
