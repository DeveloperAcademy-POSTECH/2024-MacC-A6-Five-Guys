//
//  SDReadingProgress.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
final class ReadingProgress {
    var readingRecords: [String: ReadingRecord]
    var lastReadDate: Date?
    var lastPagesRead: Int = 1

    init(readingRecords: [String: ReadingRecord] = [:], lastReadDate: Date? = nil, lastPagesRead: Int = 1) {
        self.readingRecords = readingRecords
        self.lastReadDate = lastReadDate
        self.lastPagesRead = lastPagesRead
    }
}
