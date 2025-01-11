//
//  BookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

protocol BookRepository {
    func fetchBooks() -> Result<[UserBook1], RepositoryError>
    func fetchBook(by id: UUID) -> Result<UserBook1, RepositoryError>
    
    func addBook(_ book: UserBook1) -> Result<Void, RepositoryError>
    func updateBook(_ book: UserBook1) -> Result<Void, RepositoryError>
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
