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
    static var sampleBookSearchItem: BookSearchItem { makeBookSearchItem(title: "샘플 완독 도서") }

    static func makeBookSearchItem(
        title: String,
        author: String = "한입독서 팀",
        cover: String? = nil,
        publisher: String = "Five Guys Press",
        isbn13: String = "9781234567890",
        pubDate: String = "20250101"
    ) -> BookSearchItem {
        BookSearchItem(
            title: title,
            author: author,
            cover: cover,
            publisher: publisher,
            isbn13: isbn13,
            pubDate: pubDate
        )
    }

    static var sampleSearchBooks: [BookSearchItem] {
        [
            sampleBookSearchItem,
            makeBookSearchItem(
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
        let today = DefaultReadingDateProvider().today()
        let startDate = Calendar.app.date(byAdding: .day, value: -1, to: today)
        let endDate = Calendar.app.date(byAdding: .day, value: 14, to: today)

        model.setSelectedBook(sampleBookSearchItem)
        model.setPageRange(start: 1, end: 320)
        model.setReadingPeriod(startDate: startDate, endDate: endDate)
        model.setNonReadingDays([])
        return model
    }

    static func makeBookSearchViewModel(
        books: [BookSearchItem],
        selectedBook: BookSearchItem? = nil
    ) -> BookSearchViewModel {
        let useCase = BookSearchUseCase(
            bookSearchProvider: PreviewBookSearchProvider(books: books)
        )
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)
        viewModel.books = books
        viewModel.selectedBook = selectedBook
        return viewModel
    }

    static func makeBookSearchViewModel() -> BookSearchViewModel {
        makeBookSearchViewModel(books: sampleSearchBooks)
    }
}

struct PreviewBookSearchProvider: BookSearchProviding {
    let books: [BookSearchItem]
    let totalPages: Int

    init(books: [BookSearchItem], totalPages: Int = 320) {
        self.books = books
        self.totalPages = totalPages
    }

    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        books
    }

    func fetchBookTotalPages(isbn: String) async throws -> Int {
        totalPages
    }
}
#endif
