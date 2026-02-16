//
//  ReadingDateSettingViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/16/26.
//

import Foundation

@MainActor
final class ReadingDateSettingViewModel {
    private let readingGoalMetricsUseCase: any ReadingGoalMetricsUsing

    init(readingGoalMetricsUseCase: any ReadingGoalMetricsUsing) {
        self.readingGoalMetricsUseCase = readingGoalMetricsUseCase
    }

    func dayCount(startDate: Date?, endDate: Date?) -> Int {
        guard let startDate, let endDate else { return 1 }
        return readingGoalMetricsUseCase.dayCount(startDate: startDate, endDate: endDate)
    }

    func pagesPerDay(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date?,
        endDate: Date?
    ) -> Int {
        let totalPages = readingGoalMetricsUseCase.totalPages(
            startPage: startPage,
            targetEndPage: targetEndPage
        )
        let totalDays = dayCount(startDate: startDate, endDate: endDate)
        return readingGoalMetricsUseCase.pagesPerDay(totalPages: totalPages, totalDays: totalDays)
    }
}
