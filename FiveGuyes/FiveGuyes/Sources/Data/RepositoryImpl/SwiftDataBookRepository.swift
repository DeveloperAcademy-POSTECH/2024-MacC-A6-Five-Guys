//
//  SwiftDataBookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation
import SwiftData

final class SwiftDataBookRepository: BookRepository {
    typealias SDUserBook = UserBookSchemaV2.UserBookV2
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // MARK: - Initial Methods

    @MainActor init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    // MARK: - Basic CRUD Operations

    func fetchBooks() async throws -> [FGUserBook] {
        do {
            let swiftDatabooks = try modelContext.fetch(FetchDescriptor<SDUserBook>())
            let books = swiftDatabooks.map { $0.toFGUserBook() }
            return books
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    func fetchBook(by id: UUID) async throws -> FGUserBook {
        let book = try await findSwiftDataBook(by: id)
        return book.toFGUserBook()
    }
    
    func addBook(_ book: FGUserBook) async throws {
        let swiftDataBook = book.toUserBookV2()
        modelContext.insert(swiftDataBook)

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed
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
            throw RepositoryError.updateFailed
        }
    }
    
    func deleteBook(by id: UUID) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: id)

        do {
            modelContext.delete(swiftDataBook)
            try modelContext.save()
        } catch {
            throw RepositoryError.deleteFailed
        }
    }

    // MARK: - Filtering Operations

    func getCompletedBooks() async throws -> [FGUserBook] {
        var fetchDescriptor: FetchDescriptor<SDUserBook> = .init(
            predicate: #Predicate { book in
                book.completionStatus.isCompleted == true
            }
        )

        do {
            let swiftDataBooks = try modelContext.fetch(fetchDescriptor)
            return swiftDataBooks.map { $0.toFGUserBook() }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    func getReadingBooks() async throws -> [FGUserBook] {
        var fetchDescriptor: FetchDescriptor<SDUserBook> = .init(
            predicate: #Predicate { book in
                book.completionStatus.isCompleted == false
            }
        )

        do {
            let swiftDataBooks = try modelContext.fetch(fetchDescriptor)
            return swiftDataBooks.map { $0.toFGUserBook() }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    // MARK: - Partial Update Operations

    func updateReadingProgress(bookId: UUID, progress: FGReadingProgress) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.readingProgress = progress.toReadingProgress()

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.updateFailed
        }
    }

    func updateSettings(bookId: UUID, settings: FGUserSetting) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.userSettings = settings.toUserSettings()

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.updateFailed
        }
    }

    func updateMetaData(bookId: UUID, metaData: FGBookMetaData) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.bookMetaData = metaData.toBookMetaData()

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.updateFailed
        }
    }

    func updateCompletionStatus(bookId: UUID, status: FGCompletionStatus) async throws {
        let swiftDataBook = try await findSwiftDataBook(by: bookId)

        swiftDataBook.completionStatus = status.toCompletionStatus()

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.updateFailed
        }
    }

    // MARK: - Helper Methods
    
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
                throw RepositoryError.notFound
            }
            return book
        } catch is RepositoryError {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
}
