//
//  getBooksStore.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Foundation

class BookViewModel: ObservableObject {
    @Published var books = [Book]()
    private let apiStore = APIStore()

    func searchBooks(query: String) {
        apiStore.fetchBooks(query: query) { [weak self] result in
            switch result {
            case .success(let books):
                self?.books = books
            case .failure(let error):
                print("Failed to fetch books: \(error)")
            }
        }
    }

    func fetchBookDetails(isbn: String, completion: @escaping (Result<Int, Error>) -> Void) {
        apiStore.fetchBookDetails(isbn: isbn, completion: completion)
    }
}
