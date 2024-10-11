//
//  DataFormat.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/11/24.
//

import Foundation

struct DateFormat {
    static func formatDate(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        return dateFormatter.string(from: date)
    }
}
