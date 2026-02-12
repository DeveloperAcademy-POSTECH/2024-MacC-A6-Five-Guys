//
//  AppDependencies.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/12/26.
//

import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let bookManagementService: any BookManagementService
    let notificationManager: any NotificationManaging
    let notificationSettingsStore: any NotificationSettingsStoring

    init(modelContainer: ModelContainer) {
        let repository = SwiftDataBookRepository(modelContainer: modelContainer)
        self.bookManagementService = DefaultBookManagementService(repository: repository)
        self.notificationManager = NotificationManager()
        self.notificationSettingsStore = UserDefaultsNotificationSettingsStore()
    }
}
