//
//  ReadingProgressProtocol.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

import Foundation

protocol ReadingProgressProtocol {
    var readingRecords: [String: ReadingRecord] { get set }
    var lastReadDate: Date? { get set }
    var lastPagesRead: Int { get set }
}
