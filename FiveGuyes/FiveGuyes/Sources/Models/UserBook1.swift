//
//  UserBook.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

struct UserBook1: Identifiable {
    let id: UUID
    let bookMetaData: BookMetaData1
    var userSettings: UserSettings1
    var readingProgress: ReadingProgress1
    var completionStatus: CompletionStatus1
}

struct BookMetaData1 {
    let title: String
    let author: String
    let coverImageURL: String?
    let totalPages: Int
}

struct UserSettings1 {
    let startPage: Int
    let targetEndPage: Int
    let startDate: Date
    let targetEndDate: Date
    let excludedReadingDays: [Date]
}

struct ReadingProgress1 {
    let dailyReadingRecords: [String: ReadingRecord] // 날짜와 읽은 페이지 수의 매핑
    let lastReadDate: Date?
    let lastReadPage: Int
}

struct CompletionStatus1 {
    let isCompleted: Bool
    let reviewAfterCompletion: String
}

// Extension to convert UserBookV2 to UserBook
extension UserBookSchemaV2.UserBookV2 {
    func toUserBook() -> UserBook1 {
        return UserBook1(
            id: self.id,
            bookMetaData: BookMetaData1(
                title: self.bookMetaData.title,
                author: self.bookMetaData.author,
                coverImageURL: self.bookMetaData.coverURL,
                totalPages: self.bookMetaData.totalPages
            ),
            userSettings: UserSettings1(
                startPage: self.userSettings.startPage,
                targetEndPage: self.userSettings.targetEndPage,
                startDate: self.userSettings.startDate,
                targetEndDate: self.userSettings.targetEndDate,
                excludedReadingDays: self.userSettings.nonReadingDays
            ),
            readingProgress: ReadingProgress1(
                dailyReadingRecords: self.readingProgress.readingRecords,
                lastReadDate: self.readingProgress.lastReadDate,
                lastReadPage: self.readingProgress.lastPagesRead
            ),
            completionStatus: CompletionStatus1(
                isCompleted: self.completionStatus.isCompleted,
                reviewAfterCompletion: self.completionStatus.completionReview
            )
        )
    }
}
