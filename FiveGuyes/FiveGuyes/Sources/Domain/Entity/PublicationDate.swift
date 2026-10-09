//
//  PublicationDate.swift
//  FiveGuyes
//
//  Created by Claude on 2026-10-09.
//

/// 출간일. 시각·타임존 없이 출처가 준 달력 날짜만 담는다. 월·일은 없을 수 있다.
struct PublicationDate: Equatable, Hashable, Sendable {
    let year: Int
    let month: Int?
    let day: Int?

    init?(year: Int, month: Int? = nil, day: Int? = nil) {
        guard year > 0,
              month.map({ (1...12).contains($0) }) ?? true,
              day.map({ (1...31).contains($0) }) ?? true
        else { return nil }

        self.year = year
        self.month = month
        self.day = day
    }
}
