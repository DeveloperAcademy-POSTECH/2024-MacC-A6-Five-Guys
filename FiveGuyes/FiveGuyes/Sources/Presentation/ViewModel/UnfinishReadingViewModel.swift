//
//  UnfinishReadingViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Observation

@MainActor
@Observable
final class UnfinishReadingViewModel {
    private(set) var isCompleting = false

    private let bookManagementService: any BookManagementService

    init(bookManagementService: any BookManagementService) {
        self.bookManagementService = bookManagementService
    }

    func completeBook(_ userBook: FGUserBook) async -> Bool {
        guard !isCompleting else { return false }

        isCompleting = true
        defer { isCompleting = false }

        do {
            try await bookManagementService.completeBook(
                id: userBook.id,
                completionDate: userBook.userSettings.targetEndDate,
                review: ""
            )
            return true
        } catch {
            print("미완독 종료 처리 중 오류 발생: \(error.localizedDescription)")
            return false
        }
    }
}
