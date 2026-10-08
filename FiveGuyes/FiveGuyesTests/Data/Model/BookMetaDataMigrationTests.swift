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

        do {
            let legacySchema = Schema([LegacyBookMetaDataSchema.BookMetaData.self])
            let configuration = ModelConfiguration(schema: legacySchema, url: storeURL)
            let container = try ModelContainer(
                for: legacySchema,
                configurations: [configuration]
            )
            container.mainContext.insert(
                LegacyBookMetaDataSchema.BookMetaData(
                    title: "기존 도서",
                    author: "기존 저자",
                    coverURL: nil,
                    totalPages: 300
                )
            )
            try container.mainContext.save()
        }

        let currentSchema = Schema([BookMetaData.self])
        let configuration = ModelConfiguration(schema: currentSchema, url: storeURL)
        let container = try ModelContainer(
            for: currentSchema,
            configurations: [configuration]
        )
        let storedItems = try container.mainContext.fetch(FetchDescriptor<BookMetaData>())
        let storedItem = try #require(storedItems.first)

        #expect(storedItems.count == 1)
        #expect(storedItem.title == "기존 도서")
        #expect(storedItem.isbn13 == nil)
    }
}

private enum LegacyBookMetaDataSchema {
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
}
