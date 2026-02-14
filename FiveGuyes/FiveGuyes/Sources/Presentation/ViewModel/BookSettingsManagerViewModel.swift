//
//  BookSettingsManagerViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/15/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class BookSettingsManagerViewModel {
    private let readingPlanUseCase: any ReadingPlanUsing

    init(readingPlanUseCase: any ReadingPlanUsing) {
        self.readingPlanUseCase = readingPlanUseCase
    }

    func today() -> Date {
        readingPlanUseCase.today()
    }
}
