//
//  MainHomeViewModel.swift
//  FiveGuyes
//
//  Created by Codex on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class MainHomeViewModel {
    private(set) var readingBooks: [FGUserBook] = []
    private(set) var completedBooks: [FGUserBook] = []

    private var bookManagementService: (any BookManagementService)?

    func configure(bookManagementService: any BookManagementService) {
        guard self.bookManagementService == nil else { return }
        self.bookManagementService = bookManagementService
    }

    func loadBooks() async {
        guard let bookManagementService else { return }

        do {
            async let readingResult = bookManagementService.fetchReadingBooks()
            async let completedResult = bookManagementService.fetchCompletedBooks()
            let (readingBooks, completedBooks) = try await (readingResult, completedResult)

            self.readingBooks = readingBooks
            self.completedBooks = completedBooks
        } catch {
            print("홈 목록 조회 중 오류 발생: \(error.localizedDescription)")
        }
    }

    func deleteBook(id: UUID) async -> Bool {
        guard let bookManagementService else { return false }

        do {
            try await bookManagementService.deleteBook(id: id)
            await loadBooks()
            return true
        } catch {
            print("데이터 삭제 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }

    func rescheduleOnAppOpen(today: Date) async -> [FGUserBook] {
        guard let bookManagementService else { return [] }
        guard !readingBooks.isEmpty else { return [] }

        let currentBooks = readingBooks
        var overdueBooks: [FGUserBook] = []

        for book in currentBooks {
            do {
                try await bookManagementService.rescheduleOnAppOpen(
                    bookId: book.id,
                    today: today
                )
            } catch ScheduleCalculationError.targetDatePassed {
                overdueBooks.append(book)
            } catch {
                print("페이지 재분배 중 오류 발생: \(error.localizedDescription)")
            }
        }

        await loadBooks()
        return overdueBooks
    }
}
