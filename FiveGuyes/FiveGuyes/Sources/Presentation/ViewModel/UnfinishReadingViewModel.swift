//
//  UnfinishReadingViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class UnfinishReadingViewModel {
    private(set) var isCompleting = false

    private let bookCompletionUseCase: any BookCompletionUsing

    init(bookCompletionUseCase: any BookCompletionUsing) {
        self.bookCompletionUseCase = bookCompletionUseCase
    }

    func completeBook(_ userBook: FGUserBook) async -> Bool {
        guard !isCompleting else { return false }

        isCompleting = true
        defer { isCompleting = false }

        do {
            try await bookCompletionUseCase.completeBook(
                id: userBook.id,
                review: ""
            )
            return true
        } catch {
            print("미완독 종료 처리 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }
}
