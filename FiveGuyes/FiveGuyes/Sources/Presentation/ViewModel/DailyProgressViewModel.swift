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

    private let dailyReadingUseCase: any DailyReadingUsing
    private let bookCompletionUseCase: any BookCompletionUsing

    init(
        dailyReadingUseCase: any DailyReadingUsing,
        bookCompletionUseCase: any BookCompletionUsing
    ) {
        self.dailyReadingUseCase = dailyReadingUseCase
        self.bookCompletionUseCase = bookCompletionUseCase
    }

    func today() -> Date {
        dailyReadingUseCase.today()
    }

    func preloadPages(userBook: FGUserBook) {
        let today = dailyReadingUseCase.today()
        guard let readingRecord = userBook.readingProgress.getDailyReadingRecord(for: today) else { return }
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

    func submit(bookId: UUID) async -> SubmitOutcome {
        guard !isSubmitting else { return .none }

        isSubmitting = true
        let pagesRead = pagesToReadToday
        defer { isSubmitting = false }

        do {
            let result = try await dailyReadingUseCase.recordReading(
                bookId: bookId,
                pagesRead: pagesRead
            )

            switch result {
            case .recorded, .dateExtended:
                return .popToRoot
            case .completed(let updatedBook):
                try await bookCompletionUseCase.completeBook(
                    id: bookId,
                    review: ""
                )
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
