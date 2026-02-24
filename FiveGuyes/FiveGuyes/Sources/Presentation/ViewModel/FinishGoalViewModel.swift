//
//  FinishGoalViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class FinishGoalViewModel {
    var pagesPerDay = 0
    private(set) var isSubmitting = false

    private let bookRegistrationUseCase: any BookRegistrationUsing
    private let readingGoalMetricsUseCase: any ReadingGoalMetricsUsing

    init(
        bookRegistrationUseCase: any BookRegistrationUsing,
        readingGoalMetricsUseCase: any ReadingGoalMetricsUsing
    ) {
        self.bookRegistrationUseCase = bookRegistrationUseCase
        self.readingGoalMetricsUseCase = readingGoalMetricsUseCase
    }

    func calculateRecommendedPagesPerDay(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date,
        excludedDays: [Date]
    ) {
        pagesPerDay = readingGoalMetricsUseCase.recommendedPagesPerDay(
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            endDate: endDate,
            excludedDays: excludedDays
        )
    }

    func registerBook(
        selectedBook: BookSearchItem,
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date,
        excludedReadingDays: [Date]
    ) async -> Bool {
        guard !isSubmitting else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let input = RegisterBookInput(
            bookMetaData: FGBookMetaData(
                title: selectedBook.title,
                author: selectedBook.author,
                coverImageURL: selectedBook.cover,
                totalPages: targetEndPage
            ),
            userSettings: FGUserSetting(
                startPage: startPage,
                targetEndPage: targetEndPage,
                startDate: startDate,
                targetEndDate: endDate,
                excludedReadingDays: excludedReadingDays
            )
        )

        do {
            _ = try await bookRegistrationUseCase.registerBook(input)
            return true
        } catch {
            print("책 등록 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }
}
