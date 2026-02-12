//
//  AppDependencies.swift
//  FiveGuyes
//
//  Created by Codex on 2/12/26.
//

import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let bookManagementService: any BookManagementService

    init(modelContainer: ModelContainer) {
        let repository = SwiftDataBookRepository(modelContainer: modelContainer)
        self.bookManagementService = DefaultBookManagementService(repository: repository)
    }
}
