//
//  MockBookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/1/25.
//

import Foundation

actor MockBookRepository: BookRepository {
    var books: [FGUserBook] = []

    func fetchBooks() async throws -> [FGUserBook] {
        return books
    }

    func fetchBook(by id: UUID) async throws -> FGUserBook {
        guard let book = books.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return book
    }

    func addBook(_ book: FGUserBook) async throws {
        books.append(book)
    }

    func updateBook(_ book: FGUserBook) async throws {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else {
            throw RepositoryError.notFound
        }
        books[index] = book
    }

    func deleteBook(by id: UUID) async throws {
        books.removeAll { $0.id == id }
    }

    func getCompletedBooks() async throws -> [FGUserBook] {
        return books.filter { $0.completionStatus.isCompleted }
    }

    func getReadingBooks() async throws -> [FGUserBook] {
        return books.filter { !$0.completionStatus.isCompleted }
    }

    func updateReadingProgress(bookId: UUID, progress: FGReadingProgress) async throws {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else {
            throw RepositoryError.notFound
        }
        var updatedBook = books[index]
        updatedBook.readingProgress = progress
        books[index] = updatedBook
    }

    func updateSettings(bookId: UUID, settings: FGUserSetting) async throws {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else {
            throw RepositoryError.notFound
        }
        var updatedBook = books[index]
        updatedBook.userSettings = settings
        books[index] = updatedBook
    }

    func updateMetaData(bookId: UUID, metaData: FGBookMetaData) async throws {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else {
            throw RepositoryError.notFound
        }
        let oldBook = books[index]
        // bookMetaData는 let이므로 책 전체를 새로 생성
        let updatedBook = FGUserBook(
            id: oldBook.id,
            bookMetaData: metaData,
            userSettings: oldBook.userSettings,
            readingProgress: oldBook.readingProgress,
            completionStatus: oldBook.completionStatus
        )
        books[index] = updatedBook
    }

    func updateCompletionStatus(bookId: UUID, status: FGCompletionStatus) async throws {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else {
            throw RepositoryError.notFound
        }
        var updatedBook = books[index]
        updatedBook.completionStatus = status
        books[index] = updatedBook
    }

    // Mock 데이터 설정 헬퍼
    func setBooks(_ books: [FGUserBook]) {
        self.books = books
    }
}
