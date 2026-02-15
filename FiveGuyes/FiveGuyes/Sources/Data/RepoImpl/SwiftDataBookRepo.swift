//
//  SwiftDataBookRepo.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation
import SwiftData

final class SwiftDataBookRepo: BookRepo {
    typealias SDUserBook = UserBookSchemaV2.UserBookV2

    // MARK: - Properties

    static let migrationCompletionVersionKey = "readingRecordKeyMigrationV1Completed"

    private let modelContext: ModelContext
    private let migrationUserDefaults: UserDefaults
    private let migrationCompletionKey: String

    // MARK: - Initial Methods

    @MainActor
    convenience init(modelContainer: ModelContainer) {
        self.init(
            modelContainer: modelContainer,
            migrationUserDefaults: .standard,
            migrationCompletionKey: Self.migrationCompletionVersionKey
        )
    }

    @MainActor
    init(
        modelContainer: ModelContainer,
        migrationUserDefaults: UserDefaults,
        migrationCompletionKey: String
    ) {
        self.modelContext = modelContainer.mainContext
        self.migrationUserDefaults = migrationUserDefaults
        self.migrationCompletionKey = migrationCompletionKey
    }

    // MARK: - Basic CRUD Operations

    func fetchBooks() async throws -> [FGUserBook] {
        do {
            try migrateReadingRecordKeysIfNeeded()
            let swiftDatabooks = try modelContext.fetch(FetchDescriptor<SDUserBook>())
            let books = swiftDatabooks.map { $0.toFGUserBook() }
            return books
        } catch {
            throw RepoError.fetchFailed
        }
    }

    func fetchBook(by id: UUID) async throws -> FGUserBook {
        try migrateReadingRecordKeysIfNeeded()
        let book = try await findSwiftDataBook(by: id)
        return book.toFGUserBook()
    }

    func addBook(_ book: FGUserBook) async throws {
        let swiftDataBook = book.toUserBookV2()
        modelContext.insert(swiftDataBook)

        do {
            try modelContext.save()
        } catch {
            throw RepoError.saveFailed
        }
    }

    func updateBook(_ book: FGUserBook) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: book.id)

        // 기존 책 데이터를 DTO를 기준으로 업데이트
        updateSwiftDataModel(swiftDataBook, with: book)

        // 저장
        do {
            try modelContext.save()
        } catch {
            throw RepoError.updateFailed
        }
    }

    func deleteBook(by id: UUID) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: id)

        do {
            modelContext.delete(swiftDataBook)
            try modelContext.save()
        } catch {
            throw RepoError.deleteFailed
        }
    }

    // MARK: - Filtering Operations

    func getCompletedBooks() async throws -> [FGUserBook] {
        let fetchDescriptor: FetchDescriptor<SDUserBook> = .init(
            predicate: #Predicate { book in
                book.completionStatus.isCompleted == true
            }
        )

        do {
            try migrateReadingRecordKeysIfNeeded()
            let swiftDataBooks = try modelContext.fetch(fetchDescriptor)
            return swiftDataBooks.map { $0.toFGUserBook() }
        } catch {
            throw RepoError.fetchFailed
        }
    }

    func getReadingBooks() async throws -> [FGUserBook] {
        let fetchDescriptor: FetchDescriptor<SDUserBook> = .init(
            predicate: #Predicate { book in
                book.completionStatus.isCompleted == false
            }
        )

        do {
            try migrateReadingRecordKeysIfNeeded()
            let swiftDataBooks = try modelContext.fetch(fetchDescriptor)
            return swiftDataBooks.map { $0.toFGUserBook() }
        } catch {
            throw RepoError.fetchFailed
        }
    }

    // MARK: - Partial Update Operations

    func updateReadingProgress(bookId: UUID, progress: FGReadingProgress) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.readingProgress = progress.toReadingProgress()

        do {
            try modelContext.save()
        } catch {
            throw RepoError.updateFailed
        }
    }

    func updateSettings(bookId: UUID, settings: FGUserSetting) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.userSettings = settings.toUserSettings()

        do {
            try modelContext.save()
        } catch {
            throw RepoError.updateFailed
        }
    }

    func updateMetaData(bookId: UUID, metaData: FGBookMetaData) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.bookMetaData = metaData.toBookMetaData()

        do {
            try modelContext.save()
        } catch {
            throw RepoError.updateFailed
        }
    }

    func updateCompletionStatus(bookId: UUID, status: FGCompletionStatus) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.completionStatus = status.toCompletionStatus()

        do {
            try modelContext.save()
        } catch {
            throw RepoError.updateFailed
        }
    }

    // MARK: - Helper Methods

    @MainActor
    func prewarmReadingRecordKeyMigrationIfNeeded() throws {
        try migrateReadingRecordKeysIfNeeded()
    }

    /// 읽기 기록 키의 legacy 포맷을 현재 도메인 정책(`Calendar.app`) 기준으로 1회 보정합니다.
    ///
    /// 왜 fetch 경계에서 1회 실행하는가:
    /// - 과거 저장 데이터와 현재 조회 키 정책이 다를 수 있어 "기록이 비어 보이는" 문제를 사전에 제거해야 합니다.
    /// - 매 조회마다 fallback 분기를 계속 두는 방식보다, 초기 1회 write-back이 이후 런타임 비용/복잡도를 줄입니다.
    private func migrateReadingRecordKeysIfNeeded() throws {
        guard !isMigrationCompleted() else { return }

        do {
            let swiftDataBooks = try modelContext.fetch(FetchDescriptor<SDUserBook>())
            var hasMutatedAnyBook = false

            for swiftDataBook in swiftDataBooks {
                let migration = ReadingRecordKeyMigrationV1(
                    records: swiftDataBook.readingProgress.readingRecords,
                    lastReadDate: swiftDataBook.readingProgress.lastReadDate
                )

                if migration.didMutate {
                    swiftDataBook.readingProgress.readingRecords = migration.migratedRecords
                    hasMutatedAnyBook = true
                }
            }

            if hasMutatedAnyBook {
                try modelContext.save()
            }

            markMigrationCompleted()
        } catch {
            // 마이그레이션 실패 시 완료 플래그를 올리지 않아 다음 fetch에서 재시도할 수 있게 합니다.
            throw RepoError.fetchFailed
        }
    }

    private func isMigrationCompleted() -> Bool {
        if migrationUserDefaults.bool(forKey: migrationCompletionKey) {
            return true
        }

        // 하위 호환: 기존 단일 완료 키가 true라면 앱 스코프 키로 승격합니다.
        guard migrationCompletionKey != Self.migrationCompletionVersionKey else {
            return false
        }

        if migrationUserDefaults.bool(forKey: Self.migrationCompletionVersionKey) {
            migrationUserDefaults.set(true, forKey: migrationCompletionKey)
            return true
        }

        return false
    }

    private func markMigrationCompleted() {
        migrationUserDefaults.set(true, forKey: migrationCompletionKey)
    }

    /// UserBook으로 기존 SwiftData 모델을  업데이트
    private func updateSwiftDataModel(_ existingBook: SDUserBook, with book: FGUserBook) {
        existingBook.userSettings = book.userSettings.toUserSettings()
        existingBook.readingProgress = book.readingProgress.toReadingProgress()
        existingBook.completionStatus = book.completionStatus.toCompletionStatus()
    }

    /// 특정 ID로 SwiftData 모델을 조회
    private func findSwiftDataBook(by id: UUID) async throws -> SDUserBook {
        var fetchDescriptor: FetchDescriptor<SDUserBook> = .init(
            predicate: #Predicate { book in
                book.id == id
            }
        )
        fetchDescriptor.fetchLimit = 1

        do {
            let books = try modelContext.fetch(fetchDescriptor)
            guard let book = books.first else {
                throw RepoError.notFound
            }
            return book
        } catch is RepoError {
            throw RepoError.notFound
        } catch {
            throw RepoError.fetchFailed
        }
    }
}

private struct ReadingRecordKeyMigrationV1 {
    let migratedRecords: [String: ReadingRecord]
    let didMutate: Bool

    init(records: [String: ReadingRecord], lastReadDate: Date?) {
        guard !records.isEmpty else {
            self.migratedRecords = records
            self.didMutate = false
            return
        }

        let dayShift = Self.inferDayShift(from: records, lastReadDate: lastReadDate)
        var migratedRecords: [String: ReadingRecord] = [:]
        migratedRecords.reserveCapacity(records.count)

        for (rawKey, record) in records {
            let shiftedKey = Self.shiftedRawKey(from: rawKey, by: dayShift)
            let normalizedRecord = Self.normalize(record: record)

            if let existing = migratedRecords[shiftedKey] {
                migratedRecords[shiftedKey] = Self.mergeRecord(existing, normalizedRecord)
            } else {
                migratedRecords[shiftedKey] = normalizedRecord
            }
        }

        self.migratedRecords = migratedRecords
        self.didMutate = migratedRecords != records
    }

    /// 기본값은 0(이동 없음)입니다. 근거가 충분할 때만 -1 또는 +1 이동을 허용합니다.
    private static func inferDayShift(from records: [String: ReadingRecord], lastReadDate: Date?) -> Int {
        guard let lastReadDate else { return 0 }
        guard let anchorKey = migrationAnchorKey(from: records),
              let anchorDate = anchorKey.toDate(),
              let expectedDate = lastReadDate.readingDateKey.toDate() else {
            return 0
        }

        let diff = Calendar.app.dateComponents([.day], from: anchorDate, to: expectedDate).day ?? 0
        return abs(diff) <= 1 ? diff : 0
    }

    private static func migrationAnchorKey(from records: [String: ReadingRecord]) -> ReadingDateKey? {
        let readKeys = records
            .filter { $0.value.pagesRead > 0 }
            .keys
            .map { ReadingDateKey.fromStoredKey($0) }

        if let latestReadKey = readKeys.max() {
            return latestReadKey
        }

        return records.keys.map { ReadingDateKey.fromStoredKey($0) }.max()
    }

    private static func shiftedRawKey(from rawKey: String, by days: Int) -> String {
        let key = ReadingDateKey.fromStoredKey(rawKey)
        guard days != 0,
              let date = key.toDate(),
              let shiftedDate = Calendar.app.date(byAdding: .day, value: days, to: date) else {
            return key.rawValue
        }

        return ReadingDateKey(date: shiftedDate).rawValue
    }

    private static func mergeRecord(_ lhs: ReadingRecord, _ rhs: ReadingRecord) -> ReadingRecord {
        let merged = ReadingRecord(
            targetPages: max(lhs.targetPages, rhs.targetPages),
            pagesRead: max(lhs.pagesRead, rhs.pagesRead)
        )
        return normalize(record: merged)
    }

    private static func normalize(record: ReadingRecord) -> ReadingRecord {
        let pagesRead = max(0, record.pagesRead)
        let targetPages = max(record.targetPages, pagesRead)
        return ReadingRecord(targetPages: targetPages, pagesRead: pagesRead)
    }
}
