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
}
