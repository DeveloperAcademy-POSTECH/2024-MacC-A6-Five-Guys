//
//  BookModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct BookModel {
    let title: String
    let author: String
    let totalPages: Int
    let startDate: Date
    let targetEndDate: Date
    var nonReadingDays: [Date]
}
