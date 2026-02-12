//
//  CompletionReviewViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CompletionReviewViewModel {
    enum SubmitOutcome {
        case none
        case popToRoot
    }

    var reflectionText = ""
    var showEmptyReviewAlert = false
    private(set) var isSubmitting = false

    private var bookManagementService: (any BookManagementService)?

    func configure(bookManagementService: any BookManagementService) {
        guard self.bookManagementService == nil else { return }
        self.bookManagementService = bookManagementService
    }

    func preloadReview(_ review: String) {
        reflectionText = review
    }

    func submit(userBookId: UUID, isUpdateMode: Bool, completionDate: Date) async -> SubmitOutcome {
        guard !isSubmitting else { return .none }

        let review = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !review.isEmpty else {
            showEmptyReviewAlert = true
            return .none
        }

        guard let bookManagementService else { return .none }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            if isUpdateMode {
                try await bookManagementService.updateCompletionReview(
                    id: userBookId,
                    review: review
                )
            } else {
                try await bookManagementService.completeBook(
                    id: userBookId,
                    completionDate: completionDate,
                    review: review
                )
            }
            return .popToRoot
        } catch {
            print("완독 소감 저장 중 오류 발생: \(error.localizedDescription)")
            return .none
        }
    }
}
