//
//  Date+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/9/24.
//

import Foundation

extension Date {
    /// 지정된 일 수만큼 날짜를 추가합니다.
    /// - Parameter days: 추가할 일 수 (음수일 경우 감소)
    /// - Returns: 일 수가 추가된 새로운 `Date`
    func addDays(_ days: Int) -> Date {
        return Calendar.app.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// `yyyy년 MM월 dd일` 형식으로 변환하여 문자열로 반환합니다.
    func toKoreanDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: self)
    }

    /// `yyyy년 M월` 형식으로 변환하여 문자열로 반환합니다.
    func calendarHeaderString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: self)
    }

    /// `MM월 dd일` 형식으로 변환하여 문자열로 반환합니다.
    func toKoreanDateStringWithoutYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일"
        return formatter.string(from: self)
    }

    /// `M월 d일 EEEE` 형식으로 변환하여 문자열로 반환합니다.
    func formattedCompletionDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: self)
    }

    /// 년과 월을 문자로 반환합니다.
    func toYearMonthString() -> String {
        let formatter = Date.FormatStyle()
            .year(.defaultDigits)
            .month(.abbreviated)
        return self.formatted(formatter)
    }
}

extension Date {
    /// 기존 호출부 호환을 위해 Date 확장에 남겨둔 wrapper입니다.
    /// 실제 키 생성 규칙은 `ReadingDateKey`가 단일 소스로 관리합니다.
    var readingDateKey: ReadingDateKey {
        ReadingDateKey(date: self, calendar: .app)
    }

    /// 기존 메서드 시그니처를 유지하면서 내부 구현만 `ReadingDateKey`로 통일합니다.
    func toYearMonthDayString() -> String {
        readingDateKey.rawValue
    }

    /// 04:00 AM을 기준으로 날짜를 조정하여 "yyyy-MM-dd" 형식으로 반환
    /// 정책 계산은 `DayBoundaryProviding`/`ReadingDateKey`로 위임하고, 호출부 호환을 위해 wrapper를 유지합니다.
    func toAdjustedYearMonthDayString(hourOffset: Int = -4) -> String {
        guard hourOffset == -4 else {
            let calendar = Calendar.app
            let adjustedDate = calendar.date(byAdding: .hour, value: hourOffset, to: self) ?? self
            return ReadingDateKey(date: adjustedDate, calendar: calendar).rawValue
        }
        return DayBoundary.shared.adjustedDayKey(from: self).rawValue
    }

    /// 기준 시각으로 조정된 날짜 반환
    func adjustedDate(hourOffset: Int = -4) -> Date {
        guard hourOffset == -4 else {
            let calendar = Calendar.app
            return calendar.date(byAdding: .hour, value: hourOffset, to: self) ?? self
        }
        return DayBoundary.shared.adjustedDate(from: self)
    }
}

extension Date {
    /// 현재 날짜가 특정 시간 범위에 포함되어 있는지 확인하는 메서드
    func isInHourRange(start: Int, end: Int, calendar: Calendar = Calendar.app) -> Bool {
        let hour = calendar.component(.hour, from: self)
        return hour >= start && hour < end
    }
}

// MARK: - 수정중 ❗️❗️❗️❗️❗️
extension Date {
    /// 시간 부분을 버리기
    var onlyDate: Date {
        let component = Calendar.app.dateComponents([.year, .month, .day], from: self)
        return Calendar.app.date(from: component) ?? Date()
    }
}
