//
//  CompletionCelebrationViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/15/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CompletionCelebrationViewModel {
    private let bookCompletionUseCase: any BookCompletionUsing

    init(bookCompletionUseCase: any BookCompletionUsing) {
        self.bookCompletionUseCase = bookCompletionUseCase
    }

    func summary(for userBook: FGUserBook) -> CompletionCelebrationSummary {
        bookCompletionUseCase.completionCelebrationSummary(for: userBook)
    }
}
