//
//  ReadingDateEditViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReadingDateEditViewModel {
    private(set) var isSubmitting = false

    private var bookManagementService: (any BookManagementService)?

    func configure(bookManagementService: any BookManagementService) {
        guard self.bookManagementService == nil else { return }
        self.bookManagementService = bookManagementService
    }

    func submitReadingPlanUpdate(
        bookId: UUID,
        startDate: Date,
        endDate: Date,
        excludedReadingDays: [Date],
        today: Date
    ) async -> Bool {
        guard !isSubmitting else { return false }
        guard let bookManagementService else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await bookManagementService.updateReadingPlan(
                bookId: bookId,
                startDate: startDate,
                targetEndDate: endDate,
                excludedReadingDays: excludedReadingDays,
                today: today
            )
            return true
        } catch {
            print("목표기간 수정 저장 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }
}
