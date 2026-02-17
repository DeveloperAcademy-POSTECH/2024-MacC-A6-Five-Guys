//
//  CompletionUseCases.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

struct CompletionCelebrationSummary: Equatable {
    let startDate: Date
    let endDate: Date
    let totalReadingDays: Int
    let pagesPerDay: Int
    
    static func make(
        for book: FGUserBook,
        endDate: Date,
        pageMath: PageMathCalculator = PageMathCalculator()
    ) -> CompletionCelebrationSummary {
        let startDate = min(book.userSettings.startDate, endDate)
        
        let totalReadingDays = max(
            book.readingProgress.dailyReadingRecords.values
                .filter { $0.pagesRead > 0 }.count, 1)
        
        let totalReadingPages = (try? pageMath.pagesBetween(
            from: book.userSettings.startPage,
            to: book.userSettings.targetEndPage
        )) ?? 0
        
        let pagesPerDay = (try? pageMath.pagesPerDay(
            totalPages: totalReadingPages,
            totalDays: totalReadingDays
        )) ?? totalReadingPages
        
        return CompletionCelebrationSummary(
            startDate: startDate,
            endDate: endDate,
            totalReadingDays: totalReadingDays,
            pagesPerDay: pagesPerDay
        )
    }
}

protocol BookCompletionUsing {
    func completeBook(id: UUID, review: String) async throws
    func updateCompletionReview(id: UUID, review: String) async throws
    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary
}

struct BookCompletionUseCase: BookCompletionUsing {
    private let completeBookUseCase: CompleteBookUseCase
    private let updateCompletionReviewUseCase: UpdateCompletionReviewUseCase
    private let todayProvider: any ReadingDateProviding
    
    init(
        completeBookUseCase: CompleteBookUseCase,
        updateCompletionReviewUseCase: UpdateCompletionReviewUseCase,
        todayProvider: any ReadingDateProviding
    ) {
        self.completeBookUseCase = completeBookUseCase
        self.updateCompletionReviewUseCase = updateCompletionReviewUseCase
        self.todayProvider = todayProvider
    }
    
    func completeBook(id: UUID, review: String) async throws {
        let completionDate = todayProvider.today()
        try await completeBookUseCase.execute(
            id: id,
            completionDate: completionDate,
            review: review
        )
    }
    
    func updateCompletionReview(id: UUID, review: String) async throws {
        try await updateCompletionReviewUseCase.execute(id: id, review: review)
    }
    
    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary {
        CompletionCelebrationSummary.make(for: book, endDate: todayProvider.today())
    }
}

struct CompleteBookUseCase {
    let repo: BookRepo
    let notificationScheduler: any ReadingNotificationScheduling
    
    func execute(id: UUID, completionDate: Date, review: String) async throws {
        let currentBook = try await repo.fetchBook(by: id)
        
        let updatedStatus = FGCompletionStatus(
            isCompleted: true,
            reviewAfterCompletion: review
        )
        
        let adjustedStartDate = min(currentBook.userSettings.startDate, completionDate)
        let updatedSettings = FGUserSetting(
            startPage: currentBook.userSettings.startPage,
            targetEndPage: currentBook.userSettings.targetEndPage,
            startDate: adjustedStartDate,
            targetEndDate: completionDate,
            excludedReadingDays: currentBook.userSettings.excludedReadingDays
        )
        
        try await repo.updateCompletionStatus(bookId: id, status: updatedStatus)
        try await repo.updateSettings(bookId: id, settings: updatedSettings)
        await notificationScheduler.clearRequests()
    }
}

struct UpdateCompletionReviewUseCase {
    let repo: BookRepo
    
    func execute(id: UUID, review: String) async throws {
        let currentBook = try await repo.fetchBook(by: id)
        
        let updatedStatus = FGCompletionStatus(
            isCompleted: currentBook.completionStatus.isCompleted,
            reviewAfterCompletion: review
        )
        
        try await repo.updateCompletionStatus(bookId: id, status: updatedStatus)
    }
}
