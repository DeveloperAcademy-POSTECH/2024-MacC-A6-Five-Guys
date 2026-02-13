//
//  BookSettingPreviewSupport.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
import Foundation

@MainActor
extension PreviewSupport {
    static var sampleAPIBook: Book { makeAPIBook(title: "샘플 완독 도서") }

    static func makeAPIBook(
        title: String,
        author: String = "한입독서 팀",
        cover: String? = nil,
        publisher: String = "Five Guys Press",
        isbn13: String = "9781234567890",
        pubDate: String = "20250101"
    ) -> Book {
        Book(
            title: title,
            author: author,
            cover: cover,
            publisher: publisher,
            isbn13: isbn13,
            pubDate: pubDate
        )
    }

    static var sampleSearchBooks: [Book] {
        [
            sampleAPIBook,
            makeAPIBook(
                title: "두 번째 샘플 도서",
                author: "홍길동",
                publisher: "Sample House",
                isbn13: "9781234567891",
                pubDate: "20240220"
            )
        ]
    }

    static func makeBookSettingInputModel() -> BookSettingInputModel {
        let model = BookSettingInputModel()
        let today = Date().adjustedDate()
        let startDate = Calendar.app.date(byAdding: .day, value: -1, to: today)
        let endDate = Calendar.app.date(byAdding: .day, value: 14, to: today)

        model.setSelectedBook(sampleAPIBook)
        model.setPageRange(start: 1, end: 320)
        model.setReadingPeriod(startDate: startDate, endDate: endDate)
        model.setNonReadingDays([])
        return model
    }

    static func makeBookSearchViewModel(
        books: [Book],
        selectedBook: Book? = nil
    ) -> BookSearchViewModel {
        let viewModel = BookSearchViewModel(bookSearchStore: PreviewBookSearchStore(books: books))
        viewModel.books = books
        viewModel.selectedBook = selectedBook
        return viewModel
    }

    static func makeBookSearchViewModel() -> BookSearchViewModel {
        makeBookSearchViewModel(books: sampleSearchBooks)
    }
}

struct PreviewBookSearchStore: BookSearching {
    let books: [Book]
    let totalPages: Int

    init(books: [Book], totalPages: Int = 320) {
        self.books = books
        self.totalPages = totalPages
    }

    func fetchBooks(query: String) async throws -> [Book] {
        books
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        totalPages
    }
}
#endif
