//
//  FGUserBook.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

struct FGUserBook: Identifiable {
    let id: UUID
    let bookMetaData: FGBookMetaData
    var userSettings: FGUserSetting
    var readingProgress: FGReadingProgress
    var completionStatus: FGCompletionStatus
}

struct FGBookMetaData {
    let title: String
    let author: String
    let coverImageURL: String?
    let totalPages: Int
}

struct FGUserSetting {
    let startPage: Int
    let targetEndPage: Int
    let startDate: Date
    let targetEndDate: Date
    let excludedReadingDays: [Date]
}

struct FGReadingProgress {
    let dailyReadingRecords: [String: ReadingRecord] // 날짜와 읽은 페이지 수의 매핑
    let lastReadDate: Date?
    let lastReadPage: Int
}

struct FGCompletionStatus {
    let isCompleted: Bool
    let reviewAfterCompletion: String
}
