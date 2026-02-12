//
//  NotiSettingViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

protocol NotificationManaging {
    func requestAuthorization() async -> Bool
    func clearRequests() async
    func setupAllNotifications(_ readingBook: FGUserBook) async
    func updateNotification(notificationType: NotificationType) async
}

extension NotificationManager: NotificationManaging {}

protocol NotificationSettingsStoring {
    func saveNotificationDisabled(_ isNotificationDisabled: Bool)
    func fetchNotificationDisabled() -> Bool
    func saveNotificationTime(hour: Int, minute: Int)
    func fetchNotificationReminderTime() -> (hour: Int, minute: Int)
}

struct UserDefaultsNotificationSettingsStore: NotificationSettingsStoring {
    func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        UserDefaultsManager.saveNotificationDisabled(isNotificationDisabled)
    }

    func fetchNotificationDisabled() -> Bool {
        UserDefaultsManager.fetchNotificationDisabled()
    }

    func saveNotificationTime(hour: Int, minute: Int) {
        UserDefaultsManager.saveNotificationTime(hour: hour, minute: minute)
    }

    func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        UserDefaultsManager.fetchNotificationReminderTime()
    }
}

@MainActor
@Observable
final class NotiSettingViewModel {
    var selectedTime: Date = Date()
    var isNotificationDisabled = false
    var isReminderTimePickerVisible = false
    var isSystemNotificationEnabled = true

    private var notificationStatusTask: Task<Void, Never>?
    private var notificationTimeTask: Task<Void, Never>?

    private let notificationManager: any NotificationManaging
    private let settingsStore: any NotificationSettingsStoring
    private let nowProvider: () -> Date

    init(
        notificationManager: any NotificationManaging = NotificationManager(),
        settingsStore: any NotificationSettingsStoring = UserDefaultsNotificationSettingsStore(),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.notificationManager = notificationManager
        self.settingsStore = settingsStore
        self.nowProvider = nowProvider
    }

    var timeSelectionRange: ClosedRange<Date> {
        let calendar = Calendar.app
        let now = nowProvider()
        let startOfDay = calendar.startOfDay(for: now)
        let start = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: startOfDay) ?? now
        let end = calendar.date(bySettingHour: 23, minute: 55, second: 0, of: startOfDay) ?? now
        return start...end
    }

    func loadPersistedSettings() {
        let calendar = Calendar.app
        let (hour, minute) = settingsStore.fetchNotificationReminderTime()

        selectedTime = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: nowProvider()
        ) ?? nowProvider()

        isNotificationDisabled = settingsStore.fetchNotificationDisabled()
    }

    func refreshSystemNotificationAuthorization() async {
        isSystemNotificationEnabled = await notificationManager.requestAuthorization()
    }

    func handleNotificationStatusChange(userBook: FGUserBook?) {
        notificationStatusTask?.cancel()
        let isDisabled = isNotificationDisabled
        settingsStore.saveNotificationDisabled(isDisabled)

        notificationStatusTask = Task {
            guard let userBook else { return }
            guard !Task.isCancelled else { return }

            if isDisabled {
                await notificationManager.clearRequests()
            } else {
                await notificationManager.setupAllNotifications(userBook)
            }
        }
    }

    func handleNotificationTimeChange(userBook: FGUserBook?) {
        notificationTimeTask?.cancel()
        let currentSelectedTime = selectedTime
        saveNotificationTime(currentSelectedTime)

        notificationTimeTask = Task {
            guard let userBook else { return }
            guard !Task.isCancelled else { return }

            await notificationManager.updateNotification(
                notificationType: .morning(readingBook: userBook)
            )
        }
    }

    private func saveNotificationTime(_ time: Date) {
        let calendar = Calendar.app
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        settingsStore.saveNotificationTime(hour: hour, minute: minute)
    }
}
