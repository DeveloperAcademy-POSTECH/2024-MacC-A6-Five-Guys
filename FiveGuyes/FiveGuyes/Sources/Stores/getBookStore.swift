//
//  getBooksStore.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Combine
import Foundation

class BookViewModel: ObservableObject {
    @Published var books = [Book]()
    private var cancellables = Set<AnyCancellable>()
    private let apiStore = APIStore()

    func searchBooks(query: String) {
        apiStore.fetchBooks(query: query)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch books: \(error)")
                }
            }, receiveValue: { [weak self] books in
                self?.books = books
            })
            .store(in: &cancellables)
    }

    func fetchBookDetails(isbn: String) -> AnyPublisher<Int, Error> {
            return apiStore.fetchBookDetails(isbn: isbn)
        }
}
