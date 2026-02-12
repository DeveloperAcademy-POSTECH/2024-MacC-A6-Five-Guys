//
//  BookSearchViewModel.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

@MainActor
final class BookSearchViewModel: ObservableObject {
    
    @Published var books = [Book]()
    @Published var selectedBook: Book?
    private let bookSearchStore: any BookSearching

    init(bookSearchStore: any BookSearching) {
        self.bookSearchStore = bookSearchStore
    }

    func searchBooks(query: String) async {
        do {
            let books = try await bookSearchStore.fetchBooks(query: query)
            self.books = books
        } catch {
            print("Failed to fetch books: \(error)")
        }
    }

    func fetchBookTotalPages(isbn: String) async -> String {
        do {
            return try await String(bookSearchStore.fetchBookTotalPages(isbn: isbn))
        } catch {
            print("Failed to fetch book details: \(error)")
            return "0"
        }
    }
    
    func selectBook(_ book: Book) {
            selectedBook = book
        }
}
