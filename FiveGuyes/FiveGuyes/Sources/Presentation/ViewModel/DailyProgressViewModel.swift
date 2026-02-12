//
//  DailyProgressViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DailyProgressViewModel {
    enum SubmitOutcome {
        case none
        case popToRoot
        case completionCelebration(book: FGUserBook)
    }

    var pagesToReadToday: Int = 0
    var showTargetExceededAlert = false
    private(set) var isSubmitting = false

    private var bookManagementService: (any BookManagementService)?

    func configure(bookManagementService: any BookManagementService) {
        guard self.bookManagementService == nil else { return }
        self.bookManagementService = bookManagementService
    }

    func preloadPages(userBook: FGUserBook, adjustedToday: Date) {
        guard let readingRecord = userBook.readingProgress.getDailyReadingRecord(for: adjustedToday) else { return }
        pagesToReadToday = readingRecord.targetPages
    }

    func requestSubmit(targetEndPage: Int) -> Bool {
        if pagesToReadToday > targetEndPage {
            showTargetExceededAlert = true
            return false
        }
        return true
    }

    func applyMaximumTargetPages(_ targetEndPage: Int) {
        pagesToReadToday = targetEndPage
    }

    func submit(bookId: UUID, readDate: Date) async -> SubmitOutcome {
        guard !isSubmitting else { return .none }
        guard let bookManagementService else { return .none }

        isSubmitting = true
        let pagesRead = pagesToReadToday
        defer { isSubmitting = false }

        do {
            let result = try await bookManagementService.recordReading(
                bookId: bookId,
                pagesRead: pagesRead,
                readDate: readDate
            )

            switch result {
            case .recorded, .dateExtended:
                return .popToRoot
            case .completed(let updatedBook):
                return .completionCelebration(book: updatedBook)
            case .exceedsTarget:
                showTargetExceededAlert = true
                return .none
            }
        } catch {
            print("독서 기록 저장 중 오류 발생: \(error.localizedDescription)")
            return .none
        }
    }
}
