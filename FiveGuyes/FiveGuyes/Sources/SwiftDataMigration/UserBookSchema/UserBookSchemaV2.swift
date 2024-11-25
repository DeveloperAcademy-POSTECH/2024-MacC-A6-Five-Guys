//
//  UserBookSchemaV2.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

enum UserBookSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
        
    static var models: [any PersistentModel.Type] {
        [UserBookV2.self]
    }
}

extension UserBookSchemaV2 {
    @Model
    final class UserBookV2 {
        @Attribute(.unique) var id = UUID()
        
        let bookMetaData: BookMetaData
        var userSettings: UserSettings
        var readingProgress: ReadingProgress
        var completionStatus: CompletionStatus
        
        // MARK: init
        init(
            bookMetaData: BookMetaData,
            userSettings: UserSettings,
            readingProgress: ReadingProgress,
            completionStatus: CompletionStatus
        ) {
            self.bookMetaData = bookMetaData
            self.userSettings = userSettings
            self.readingProgress = readingProgress
            self.completionStatus = completionStatus
        }
        
        convenience init(from userBook: UserBookSchemaV1.UserBook) {
            let bookMetaData = BookMetaData(
                title: userBook.book.title,
                author: userBook.book.author,
                coverURL: userBook.book.coverURL,
                totalPages: userBook.book.totalPages
            )
            let userSettings = UserSettings(
                startPage: 1, // 기존 데이터에 start page 기본값 추가
                targetEndPage: userBook.book.totalPages,
                startDate: userBook.book.startDate,
                targetEndDate: userBook.book.targetEndDate,
                nonReadingDays: userBook.book.nonReadingDays
            )
            let readingProgress = ReadingProgress(
                readingRecords: userBook.readingRecords,
                lastReadDate: userBook.lastReadDate,
                lastPagesRead: userBook.lastPagesRead
            )
            let completionStatus = CompletionStatus(
                isCompleted: userBook.isCompleted,
                completionReview: userBook.completionReview
            )
            
            self.init(
                bookMetaData: bookMetaData,
                userSettings: userSettings,
                readingProgress: readingProgress,
                completionStatus: completionStatus
            )
        }
    }
}
