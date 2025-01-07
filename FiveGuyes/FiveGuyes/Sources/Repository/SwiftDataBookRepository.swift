//
//  SwiftDataBookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

final class SwiftDataBookRepository: BookRepository {
    // 아마 여기에 modelContext를 넣고 책을 꺼내와야 할 듯?
    
    func fetchBooks() -> [UserBookDTO] {
        []
    }
    
    func fetchBook(by id: UUID) -> UserBookDTO? {
        nil
    }
    
    func fetchCompletedBooks() -> [UserBookDTO] {
        []
    }
    
    func addBook(_ book: UserBookDTO) -> Bool {
        true
    }
    
    func updateBook(_ book: UserBookDTO) -> Bool {
        true
    }
    
    func deleteBook(by id: UUID) -> Bool {
        true
    }
    
    
}
