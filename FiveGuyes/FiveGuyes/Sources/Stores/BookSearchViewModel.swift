//
//  BookSearchViewModel.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Foundation

@MainActor
final class BookSearchViewModel: ObservableObject {
    
    @Published var books = [Book]()
    @Published var selectedBook: Book?
    
    private let apiStore = APIStore()

    func searchBooks(query: String) async {
        do {
            let books = try await apiStore.fetchBooks(query: query)
            self.books = books
        } catch {
            print("Failed to fetch books: \(error)")
        }
    }

    func fetchBookTotalPages(isbn: String) async -> String {
        do {
            return try await String(apiStore.fetchBookTotalPages(isbn: isbn))
        } catch {
            print("Failed to fetch book details: \(error)")
            return "0"
        }
    }
    
    func selectBook(_ book: Book) {
            selectedBook = book
        }
}
