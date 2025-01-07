//
//  BookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

protocol BookRepository {
    func fetchBooks() -> [UserBookDTO]
    func fetchBook(by id: UUID) -> UserBookDTO?
    
    func fetchCompletedBooks() -> [UserBookDTO]
    
    func addBook(_ book: UserBookDTO) -> Bool
    func updateBook(_ book: UserBookDTO) -> Bool
    func deleteBook(by id: UUID) -> Bool
}
