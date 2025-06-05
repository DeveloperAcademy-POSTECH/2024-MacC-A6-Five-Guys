//
//  BookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

protocol BookRepository {
    func fetchBooks() -> Result<[FGUserBook], RepositoryError>
    func fetchBook(by id: UUID) -> Result<FGUserBook, RepositoryError>
    
    func addBook(_ book: FGUserBook) -> Result<Void, RepositoryError>
    func updateBook(_ book: FGUserBook) -> Result<Void, RepositoryError>
    func deleteBook(by id: UUID) -> Result<Void, RepositoryError>
}

// RepositoryError 정의
enum RepositoryError: Error {
    case notFound
    case saveFailed
    case updateFailed
    case deleteFailed
    case fetchFailed
}
