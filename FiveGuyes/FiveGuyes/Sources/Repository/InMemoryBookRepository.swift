//
//  InMemoryBookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

@Observable
final class InMemoryBookRepository: BookRepository {
    private var books: [UUID: UserBookDTO] = [:]
    
    // Fetch all books
    func fetchBooks() -> [UserBookDTO] {
        return Array(books.values)
    }
    
    // Fetch a single book by ID
    func fetchBook(by id: UUID) -> UserBookDTO? {
        return books[id]
    }
    
    func fetchCompletedBooks() -> [UserBookDTO] {
        []
    }
    
    // Add a new book
    func addBook(_ book: UserBookDTO) -> Bool {
        guard books[book.id] == nil else {
            print("Book with the same ID already exists.")
            return false
        }
        books[book.id] = book
        return true
    }
    
    // Update an existing book
    func updateBook(_ book: UserBookDTO) -> Bool {
        guard books[book.id] != nil else {
            print("Book not found.")
            return false
        }
        books[book.id] = book
        return true
    }
    
    // Delete a book by ID
    func deleteBook(by id: UUID) -> Bool {
        guard books[id] != nil else {
            print("Book not found.")
            return false
        }
        books.removeValue(forKey: id)
        return true
    }
}
