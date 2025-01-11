//
//  BookModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct BookDetails: Codable {
    let title: String
    let author: String
    let coverURL: String?
    let totalPages: Int
    
    var startDate: Date
    var targetEndDate: Date
    
    var nonReadingDays: [Date]
    
    init(title: String, author: String, coverURL: String? = nil, totalPages: Int, startDate: Date, targetEndDate: Date, nonReadingDays: [Date]) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
        self.startDate = startDate
        self.targetEndDate = targetEndDate
        self.nonReadingDays = nonReadingDays
    }
}
