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

    init(bookRegistrationUseCase: any BookRegistrationUsing) {
        self.bookRegistrationUseCase = bookRegistrationUseCase
    }

    func calculateRecommendedPagesPerDay(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date,
        excludedDays: [Date]
    ) {
        let dateMath = DateMathCalculator()
        let pageMath = PageMathCalculator()

        do {
            let totalDays = try dateMath.validDays(
                from: startDate,
                to: endDate,
                excluding: excludedDays
            )
            let result = try pageMath.dividePages(
                from: startPage,
                to: targetEndPage,
                over: totalDays
            )

            pagesPerDay = result.daily
        } catch {
            pagesPerDay = 0
        }
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
