//
//  MainHomeViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class MainHomeViewModel {
    private(set) var readingBooks: [FGUserBook] = []
    private(set) var completedBooks: [FGUserBook] = []

    private let readingLibraryUseCase: any ReadingLibraryUsing

    init(readingLibraryUseCase: any ReadingLibraryUsing) {
        self.readingLibraryUseCase = readingLibraryUseCase
    }

    func loadBooks() async {
        do {
            let bookLists = try await readingLibraryUseCase.fetchLibrarySnapshot()

            self.readingBooks = bookLists.readingBooks
            self.completedBooks = bookLists.completedBooks
        } catch {
            print("홈 목록 조회 중 오류 발생: \(error.localizedDescription)")
        }
    }

    func deleteBook(id: UUID) async -> Bool {
        do {
            try await readingLibraryUseCase.deleteBook(id: id)
            await loadBooks()
            return true
        } catch {
            print("데이터 삭제 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }

    func today() -> Date {
        readingLibraryUseCase.today()
    }

    func rescheduleOnAppOpen() async -> [FGUserBook] {
        guard !readingBooks.isEmpty else { return [] }

        let currentBooks = readingBooks
        var overdueBooks: [FGUserBook] = []

        for book in currentBooks {
            do {
                try await readingLibraryUseCase.rescheduleOnAppOpen(bookId: book.id)
            } catch ScheduleCalculationError.targetDatePassed {
                overdueBooks.append(book)
            } catch {
                print("페이지 재분배 중 오류 발생: \(error.localizedDescription)")
            }
        }

        await loadBooks()
        return overdueBooks
    }

    func setupNotificationsForCurrentBook() async {
        guard let currentReadingBook = readingBooks.first else { return }

        await readingLibraryUseCase.setupNotifications(for: currentReadingBook)
    }
}
