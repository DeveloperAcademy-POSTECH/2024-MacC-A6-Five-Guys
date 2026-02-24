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

    private let bookCompletionUseCase: any BookCompletionUsing

    init(bookCompletionUseCase: any BookCompletionUsing) {
        self.bookCompletionUseCase = bookCompletionUseCase
    }

    func preloadReview(_ review: String) {
        reflectionText = review
    }

    func submit(userBookId: UUID, isUpdateMode: Bool) async -> SubmitOutcome {
        guard !isSubmitting else { return .none }

        let review = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !review.isEmpty else {
            showEmptyReviewAlert = true
            return .none
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            if isUpdateMode {
                try await bookCompletionUseCase.updateCompletionReview(
                    id: userBookId,
                    review: review
                )
            } else {
                try await bookCompletionUseCase.completeBook(
                    id: userBookId,
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
