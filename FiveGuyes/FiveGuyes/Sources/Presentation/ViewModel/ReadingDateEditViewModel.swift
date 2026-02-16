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

    private let readingPlanUseCase: any ReadingPlanUsing

    init(readingPlanUseCase: any ReadingPlanUsing) {
        self.readingPlanUseCase = readingPlanUseCase
    }

    func today() -> Date {
        readingPlanUseCase.today()
    }

    func submitReadingPlanUpdate(
        bookId: UUID,
        startDate: Date,
        endDate: Date,
        excludedReadingDays: [Date]
    ) async -> Bool {
        guard !isSubmitting else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await readingPlanUseCase.updateReadingPlan(
                bookId: bookId,
                startDate: startDate,
                targetEndDate: endDate,
                excludedReadingDays: excludedReadingDays
            )
            return true
        } catch {
            print("목표기간 수정 저장 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }
}
