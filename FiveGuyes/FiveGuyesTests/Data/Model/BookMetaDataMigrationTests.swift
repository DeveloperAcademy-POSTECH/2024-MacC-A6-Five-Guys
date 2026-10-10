//
//  BookMetaDataMigrationTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

@testable import FiveGuyes
import Foundation
import SwiftData
import Testing

@Suite("BookMetaData 경량 마이그레이션 테스트")
@MainActor
struct BookMetaDataMigrationTests {
    @Test("기존 저장소에 ISBN-13 선택 필드를 추가하면 기존 레코드는 nil로 읽힌다")
    func addingOptionalISBN13MigratesExistingStore() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BookMetaDataMigrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let storeURL = storeDirectory.appendingPathComponent("legacy.store")
        let bookID = UUID()

        try writeLegacyStore(at: storeURL, bookID: bookID)

        let container = try migratedContainer(at: storeURL)
        let storedItems = try container.mainContext.fetch(FetchDescriptor<UserBookSchemaV2.UserBookV2>())
        let storedItem = try #require(storedItems.first)
        #expect(storedItems.count == 1)
        #expect(storedItem.id == bookID)
        #expect(storedItem.bookMetaData.title == "기존 도서")
        #expect(storedItem.bookMetaData.isbn13 == nil)
        #expect(storedItem.userSettings.startPage == 10)
    }

    private func writeLegacyStore(at storeURL: URL, bookID: UUID) throws {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let endDate = Date(timeIntervalSince1970: 1_700_604_800)
        let lastReadDate = Date(timeIntervalSince1970: 1_700_086_400)
        let legacySchema = Schema([LegacyUserBookSchema.UserBookV2.self])
        let configuration = ModelConfiguration(schema: legacySchema, url: storeURL)
        let container = try ModelContainer(for: legacySchema, configurations: [configuration])
        container.mainContext.insert(
            LegacyUserBookSchema.UserBookV2(
                id: bookID,
                bookMetaData: LegacyUserBookSchema.BookMetaData(
                    title: "기존 도서",
                    author: "기존 저자",
                    coverURL: "https://example.com/legacy-cover.jpg",
                    totalPages: 300
                ),
                userSettings: LegacyUserBookSchema.UserSettings(
                    startPage: 10,
                    targetEndPage: 290,
                    startDate: startDate,
                    targetEndDate: endDate,
                    nonReadingDays: [startDate],
                    startDateKey: "2023-11-15",
                    targetEndDateKey: "2023-11-22",
                    nonReadingDayKeys: ["2023-11-15"]
                ),
                readingProgress: LegacyUserBookSchema.ReadingProgress(
                    readingRecords: [:],
                    lastReadDate: lastReadDate,
                    lastPagesRead: 42
                ),
                completionStatus: LegacyUserBookSchema.CompletionStatus(
                    isCompleted: true,
                    completionReview: "기존 소감"
                )
            )
        )
        try container.mainContext.save()
    }

    private func migratedContainer(at storeURL: URL) throws -> ModelContainer {
        let currentSchema = Schema([UserBookSchemaV2.UserBookV2.self])
        let configuration = ModelConfiguration(schema: currentSchema, url: storeURL)
        return try ModelContainer(for: currentSchema, configurations: [configuration])
    }

}

private enum LegacyUserBookSchema {
    @Model
    final class UserBookV2 {
        @Attribute(.unique) var id: UUID

        @Relationship(deleteRule: .cascade)
        var bookMetaData: BookMetaData
        @Relationship(deleteRule: .cascade)
        var userSettings: UserSettings
        @Relationship(deleteRule: .cascade)
        var readingProgress: ReadingProgress
        @Relationship(deleteRule: .cascade)
        var completionStatus: CompletionStatus

        init(
            id: UUID,
            bookMetaData: BookMetaData,
            userSettings: UserSettings,
            readingProgress: ReadingProgress,
            completionStatus: CompletionStatus
        ) {
            self.id = id
            self.bookMetaData = bookMetaData
            self.userSettings = userSettings
            self.readingProgress = readingProgress
            self.completionStatus = completionStatus
        }
    }

    @Model
    final class BookMetaData {
        var title: String
        var author: String
        var coverURL: String?
        var totalPages: Int

        init(title: String, author: String, coverURL: String?, totalPages: Int) {
            self.title = title
            self.author = author
            self.coverURL = coverURL
            self.totalPages = totalPages
        }
    }

    @Model
    final class UserSettings {
        var startPage: Int
        var targetEndPage: Int
        var startDate: Date
        var targetEndDate: Date
        var nonReadingDays: [Date]
        var startDateKey: String?
        var targetEndDateKey: String?
        var nonReadingDayKeys: [String]?

        init(
            startPage: Int,
            targetEndPage: Int,
            startDate: Date,
            targetEndDate: Date,
            nonReadingDays: [Date],
            startDateKey: String?,
            targetEndDateKey: String?,
            nonReadingDayKeys: [String]?
        ) {
            self.startPage = startPage
            self.targetEndPage = targetEndPage
            self.startDate = startDate
            self.targetEndDate = targetEndDate
            self.nonReadingDays = nonReadingDays
            self.startDateKey = startDateKey
            self.targetEndDateKey = targetEndDateKey
            self.nonReadingDayKeys = nonReadingDayKeys
        }
    }

    @Model
    final class ReadingProgress {
        var readingRecords: [String: ReadingRecord]
        var lastReadDate: Date?
        var lastPagesRead: Int

        init(readingRecords: [String: ReadingRecord], lastReadDate: Date?, lastPagesRead: Int) {
            self.readingRecords = readingRecords
            self.lastReadDate = lastReadDate
            self.lastPagesRead = lastPagesRead
        }
    }

    @Model
    final class CompletionStatus {
        var isCompleted: Bool
        var completionReview: String

        init(isCompleted: Bool, completionReview: String) {
            self.isCompleted = isCompleted
            self.completionReview = completionReview
        }
    }
}
