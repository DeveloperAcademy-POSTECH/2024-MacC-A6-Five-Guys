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
    private static let settingsDateKeyMigrationVersionKey = "settingsDateKeyMigrationV1Completed"

    private let modelContext: ModelContext
    private let migrationUserDefaults: UserDefaults
    private let migrationCompletionKey: String
    private let settingsDateKeyMigrationCompletionKey: String
    private let migrationLogger: any MigrationDiagnosticLogging

    // MARK: - Initial Methods

    @MainActor
    convenience init(modelContainer: ModelContainer) {
        self.init(
            modelContainer: modelContainer,
            migrationUserDefaults: .standard,
            migrationCompletionKey: Self.migrationCompletionVersionKey,
            migrationLogger: SystemMigrationDiagnosticLogger()
        )
    }

    @MainActor
    init(
        modelContainer: ModelContainer,
        migrationUserDefaults: UserDefaults,
        migrationCompletionKey: String,
        migrationLogger: any MigrationDiagnosticLogging = SystemMigrationDiagnosticLogger()
    ) {
        self.modelContext = modelContainer.mainContext
        self.migrationUserDefaults = migrationUserDefaults
        self.migrationCompletionKey = migrationCompletionKey
        self.settingsDateKeyMigrationCompletionKey = "\(migrationCompletionKey).\(Self.settingsDateKeyMigrationVersionKey)"
        self.migrationLogger = migrationLogger
    }

    // MARK: - Basic CRUD Operations

    func fetchBooks() async throws -> [FGUserBook] {
        do {
            try migrateStorageIfNeeded()
            let swiftDatabooks = try modelContext.fetch(FetchDescriptor<SDUserBook>())
            let books = swiftDatabooks.map { $0.toFGUserBook() }
            return books
        } catch {
            throw RepoError.fetchFailed
        }
    }

    func fetchBook(by id: UUID) async throws -> FGUserBook {
        try migrateStorageIfNeeded()
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

        updateSwiftDataModel(swiftDataBook, with: book)

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
            try migrateStorageIfNeeded()
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
            try migrateStorageIfNeeded()
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
        try migrateStorageIfNeeded()
    }

    private func migrateStorageIfNeeded() throws {
        try Self.runMigrationPipelineIfNeeded(using: makeMigrationDependencies())
    }

    private func makeMigrationDependencies() -> MigrationDependencies {
        MigrationDependencies(
            modelContext: modelContext,
            migrationUserDefaults: migrationUserDefaults,
            migrationCompletionKey: migrationCompletionKey,
            settingsDateKeyMigrationCompletionKey: settingsDateKeyMigrationCompletionKey,
            migrationLogger: migrationLogger
        )
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

    struct MigrationDependencies {
        let modelContext: ModelContext
        let migrationUserDefaults: UserDefaults
        let migrationCompletionKey: String
        let settingsDateKeyMigrationCompletionKey: String
        let migrationLogger: any MigrationDiagnosticLogging
    }
}
