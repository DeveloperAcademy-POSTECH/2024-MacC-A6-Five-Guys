//
//  ReadingGoalMetricsUseCase.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

import Foundation

protocol ReadingGoalMetricsUsing {
    func dayCount(startDate: Date, endDate: Date) -> Int
    func totalPages(startPage: Int, targetEndPage: Int) -> Int
    func pagesPerDay(totalPages: Int, totalDays: Int) -> Int
    func recommendedPagesPerDay(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date,
        excludedDays: [Date]
    ) -> Int
}

struct ReadingGoalMetricsUseCase: ReadingGoalMetricsUsing {
    private let dateMathCalculator: DateMathCalculator
    private let pageMathCalculator: PageMathCalculator

    init(
        dateMathCalculator: DateMathCalculator = DateMathCalculator(),
        pageMathCalculator: PageMathCalculator = PageMathCalculator()
    ) {
        self.dateMathCalculator = dateMathCalculator
        self.pageMathCalculator = pageMathCalculator
    }

    func dayCount(startDate: Date, endDate: Date) -> Int {
        (try? dateMathCalculator.daysBetween(from: startDate, to: endDate)) ?? 1
    }

    func totalPages(startPage: Int, targetEndPage: Int) -> Int {
        (try? pageMathCalculator.pagesBetween(from: startPage, to: targetEndPage)) ?? 0
    }

    func pagesPerDay(totalPages: Int, totalDays: Int) -> Int {
        (try? pageMathCalculator.pagesPerDay(totalPages: totalPages, totalDays: totalDays)) ?? totalPages
    }

    func recommendedPagesPerDay(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        endDate: Date,
        excludedDays: [Date]
    ) -> Int {
        do {
            let totalDays = try dateMathCalculator.validDays(
                from: startDate,
                to: endDate,
                excluding: excludedDays
            )
            let pagePlan = try pageMathCalculator.dividePages(
                from: startPage,
                to: targetEndPage,
                over: totalDays
            )

            return pagePlan.daily
        } catch {
            return 0
        }
    }
}
