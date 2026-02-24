//
//  BookSearchViewModel.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Foundation
import Observation

@MainActor
@Observable
final class BookSearchViewModel {
    struct CompletionSelection: Equatable {
        let selectedBook: BookSearchItem
        let totalPages: Int
    }

    var books = [BookSearchItem]()
    var selectedBook: BookSearchItem?
    var showSearchConfigAlert = false
    var searchConfigAlertMessage = ""
    private(set) var isCompletingSelection = false
    private let bookSearchUseCase: any BookSearchUsing
    private let missingAPIKeyAlertMessage = "검색 기능 설정(API_KEY)이 누락되었어요. 앱 설정을 확인한 뒤 다시 시도해주세요."

    init(bookSearchUseCase: any BookSearchUsing) {
        self.bookSearchUseCase = bookSearchUseCase
    }

    func searchBooks(query: String) async {
        do {
            let books = try await bookSearchUseCase.fetchBooks(query: query)
            self.books = books
        } catch {
            handleSearchError(error)
        }
    }

    func fetchBookTotalPages(isbn: String) async -> String {
        do {
            return try await String(bookSearchUseCase.fetchBookTotalPages(isbn: isbn))
        } catch {
            handleSearchError(error)
            return "0"
        }
    }

    func selectBook(_ book: BookSearchItem) {
        selectedBook = book
    }

    func completeSelection() async -> CompletionSelection? {
        guard !isCompletingSelection, let selectedBook else { return nil }

        isCompletingSelection = true
        defer { isCompletingSelection = false }

        let totalPagesString = await fetchBookTotalPages(isbn: selectedBook.isbn13)
        let totalPages = Int(totalPagesString) ?? 0

        return CompletionSelection(
            selectedBook: selectedBook,
            totalPages: totalPages
        )
    }

    private func handleSearchError(_ error: Error) {
        if let networkError = error as? BookSearchNetworkError, networkError == .missingAPIKey {
            searchConfigAlertMessage = missingAPIKeyAlertMessage
            showSearchConfigAlert = true
        }
        print("Book search failed: \(error)")
    }
}
