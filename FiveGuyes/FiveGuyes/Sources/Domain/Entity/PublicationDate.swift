//
//  PublicationDate.swift
//  FiveGuyes
//
//  Created by Claude on 2026-10-09.
//

import Foundation

/// 출간일. 시각·타임존 없이 출처가 준 달력 날짜만 담는다. 월·일은 없을 수 있다.
struct PublicationDate: Hashable, Sendable {
    let year: Int
    let month: Int?
    let day: Int?

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    /// 일이 있으면 월도 있어야 하고, 연·월·일이 모두 있으면 그레고리력에 실제로 있는 날짜여야 한다.
    init?(year: Int, month: Int? = nil, day: Int? = nil) {
        guard year > 0,
              month.map({ (1...12).contains($0) }) ?? true
        else { return nil }

        if let day {
            guard let month,
                  DateComponents(calendar: Self.calendar, year: year, month: month, day: day)
                      .isValidDate(in: Self.calendar)
            else { return nil }
        }

        self.year = year
        self.month = month
        self.day = day
    }
}
