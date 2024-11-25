//
//  ReadingProgress.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation

struct ReadingProgress: ReadingProgressProtocol, Codable {
    var readingRecords: [String: ReadingRecord] = [:]
    var lastReadDate: Date?
    var lastPagesRead: Int = 1
}
