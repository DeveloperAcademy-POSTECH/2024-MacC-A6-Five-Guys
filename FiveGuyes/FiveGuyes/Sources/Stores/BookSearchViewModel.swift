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
    @Published var isLoading = false
    @Published var isDelaying: Bool = false
    private var debounceWorkItem: DispatchWorkItem? // 딜레이를 위한 작업 아이템
        
    private let apiStore = APIStore()

    func searchBooks(query: String) async {
        self.isLoading = true
        do {
            let books = try await apiStore.fetchBooks(query: query)
            self.books = books
        } catch {
            print("Failed to fetch books: \(error)")
        }
        self.isLoading = false
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
