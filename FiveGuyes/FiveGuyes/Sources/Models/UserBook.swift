//
//  UserBook.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

struct UserBook: Identifiable {
    let id: UUID
    let bookMetaData: BookMetaData
    var userSettings: UserSettings
    var readingProgress: ReadingProgress
    var completionStatus: CompletionStatus
}

struct BookMetaData {
    let title: String
    let author: String
    let coverImageURL: String?
    let totalPages: Int
}

struct UserSettings {
    let startPage: Int
    let targetEndPage: Int
    let startDate: Date
    let targetEndDate: Date
    let excludedReadingDays: [Date]
}

struct ReadingProgress {
    let dailyReadingRecords: [String: ReadingRecord] // 날짜와 읽은 페이지 수의 매핑
    let lastReadDate: Date?
    let lastReadPage: Int
}

struct CompletionStatus {
    let isCompleted: Bool
    let reviewAfterCompletion: String
}

// Extension to convert UserBookV2 to UserBook
extension UserBookSchemaV2.UserBookV2 {
    func toUserBook() -> UserBook {
        return UserBook(
            id: self.id,
            bookMetaData: BookMetaData(
                title: self.bookMetaData.title,
                author: self.bookMetaData.author,
                coverImageURL: self.bookMetaData.coverURL,
                totalPages: self.bookMetaData.totalPages
            ),
            userSettings: UserSettings(
                startPage: self.userSettings.startPage,
                targetEndPage: self.userSettings.targetEndPage,
                startDate: self.userSettings.startDate,
                targetEndDate: self.userSettings.targetEndDate,
                excludedReadingDays: self.userSettings.nonReadingDays
            ),
            readingProgress: ReadingProgress(
                dailyReadingRecords: self.readingProgress.readingRecords,
                lastReadDate: self.readingProgress.lastReadDate,
                lastReadPage: self.readingProgress.lastPagesRead
            ),
            completionStatus: CompletionStatus(
                isCompleted: self.completionStatus.isCompleted,
                reviewAfterCompletion: self.completionStatus.completionReview
            )
        )
    }
}
