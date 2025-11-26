//
//  BookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

protocol BookRepository {
    // MARK: - Basic CRUD Operations
    func fetchBooks() async throws -> [FGUserBook]
    func fetchBook(by id: UUID) async throws -> FGUserBook

    func addBook(_ book: FGUserBook) async throws
    func updateBook(_ book: FGUserBook) async throws
    func deleteBook(by id: UUID) async throws

    // MARK: - Filtering Operations
    func getCompletedBooks() async throws -> [FGUserBook]
    func getReadingBooks() async throws -> [FGUserBook]

    // MARK: - Partial Update Operations
    func updateReadingProgress(bookId: UUID, progress: FGReadingProgress) async throws
    func updateSettings(bookId: UUID, settings: FGUserSetting) async throws
    func updateMetaData(bookId: UUID, metaData: FGBookMetaData) async throws
    func updateCompletionStatus(bookId: UUID, status: FGCompletionStatus) async throws
}

// RepositoryError 정의
enum RepositoryError: Error {
    case notFound
    case saveFailed
    case updateFailed
    case deleteFailed
    case fetchFailed
}
