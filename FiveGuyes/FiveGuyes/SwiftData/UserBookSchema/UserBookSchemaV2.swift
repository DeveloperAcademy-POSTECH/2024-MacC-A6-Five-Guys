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
    final class UserBookV2: Identifiable {
        @Attribute(.unique) var id = UUID()
        
        @Relationship(deleteRule: .cascade)
        var bookMetaData: SDBookMetaData
        @Relationship(deleteRule: .cascade)
        var userSettings: SDUserSettings
        @Relationship(deleteRule: .cascade)
        var readingProgress: SDReadingProgress
        @Relationship(deleteRule: .cascade)
        var completionStatus: SDCompletionStatus
        
        // MARK: init
        init(
            bookMetaData: SDBookMetaData,
            userSettings: SDUserSettings,
            readingProgress: SDReadingProgress,
            completionStatus: SDCompletionStatus
        ) {
            self.bookMetaData = bookMetaData
            self.userSettings = userSettings
            self.readingProgress = readingProgress
            self.completionStatus = completionStatus
        }
        
        convenience init(from userBook: UserBookSchemaV1.UserBook) {
            let bookMetaData = SDBookMetaData(
                title: userBook.book.title,
                author: userBook.book.author,
                coverURL: userBook.book.coverURL,
                totalPages: userBook.book.totalPages
            )
            let userSettings = SDUserSettings(
                startPage: 1, // 기존 데이터에 start page 기본값 추가
                targetEndPage: userBook.book.totalPages,
                startDate: userBook.book.startDate,
                targetEndDate: userBook.book.targetEndDate,
                nonReadingDays: userBook.book.nonReadingDays
            )
            let readingProgress = SDReadingProgress(
                readingRecords: userBook.readingRecords,
                lastReadDate: userBook.lastReadDate,
                lastPagesRead: userBook.lastPagesRead
            )
            let completionStatus = SDCompletionStatus(
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

extension UserBookSchemaV2.UserBookV2 {
    static let dummyUserBookV2 = UserBookSchemaV2.UserBookV2(
        bookMetaData: SDBookMetaData(
            title: "더미 책 제목",
            author: "더미 작가",
            coverURL: "https://dummyimage.com/cover",
            totalPages: 300
        ),
        userSettings: SDUserSettings(
            startPage: 1,
            targetEndPage: 300,
            startDate: Date(), // 현재 날짜
            targetEndDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(), // 30일 후
            nonReadingDays: []
        ),
        readingProgress: SDReadingProgress(
            readingRecords: [:], // 비어 있는 읽기 기록
            lastReadDate: nil,
            lastPagesRead: 0
        ),
        completionStatus: SDCompletionStatus(
            isCompleted: false,
            completionReview: ""
        )
    )
}
