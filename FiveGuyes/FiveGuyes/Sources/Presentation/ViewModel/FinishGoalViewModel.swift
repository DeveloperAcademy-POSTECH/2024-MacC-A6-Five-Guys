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

    private let bookManagementService: any BookManagementService

    init(bookManagementService: any BookManagementService) {
        self.bookManagementService = bookManagementService
    }

    func calculateRecommendedPagesPerDay(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date,
        excludedDays: [Date]
    ) {
        let totalDays = try? ReadingDateCalculator().calculateValidReadingDays(
            startDate: startDate,
            endDate: endDate,
            excludedDates: excludedDays
        )

        guard let totalDays, totalDays > 0 else {
            pagesPerDay = 0
            return
        }

        pagesPerDay = ReadingPagesCalculator().calculatePagesPerDayAndRemainder(
            totalDays: totalDays,
            startPage: startPage,
            endPage: targetEndPage
        ).pagesPerDay
    }

    func registerBook(
        selectedBook: Book,
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
            _ = try await bookManagementService.registerBook(input)
            return true
        } catch {
            print("책 등록 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }
}
