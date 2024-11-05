//
//  getBooksStore.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Foundation

@MainActor
class BookViewModel: ObservableObject {
    @Published var books = [Book]()
    private let apiStore = APIStore()

    func searchBooks(query: String) async {
        do {
            let books = try await apiStore.fetchBooks(query: query)
            self.books = books
        } catch {
            print("Failed to fetch books: \(error)")
        }
    }

    func fetchBookDetails(isbn: String) async -> Int? {
        do {
            return try await apiStore.fetchBookDetails(isbn: isbn)
        } catch {
            print("Failed to fetch book details: \(error)")
            return nil
        }
    }
}