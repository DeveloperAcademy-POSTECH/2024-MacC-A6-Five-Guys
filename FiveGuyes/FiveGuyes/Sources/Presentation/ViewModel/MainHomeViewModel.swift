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

    private let bookManagementService: any BookManagementService
    private let notificationManager: any NotificationManaging

    init(
        bookManagementService: any BookManagementService,
        notificationManager: any NotificationManaging
    ) {
        self.bookManagementService = bookManagementService
        self.notificationManager = notificationManager
    }

    func loadBooks() async {
        do {
            let readingBooks = try await bookManagementService.fetchReadingBooks()
            let completedBooks = try await bookManagementService.fetchCompletedBooks()

            self.readingBooks = readingBooks
            self.completedBooks = completedBooks
        } catch {
            print("홈 목록 조회 중 오류 발생: \(error.localizedDescription)")
        }
    }

    func deleteBook(id: UUID) async -> Bool {
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

    func setupNotificationsForCurrentBook() async {
        guard let currentReadingBook = readingBooks.first else { return }

        await notificationManager.setupAllNotifications(currentReadingBook)
    }
}
