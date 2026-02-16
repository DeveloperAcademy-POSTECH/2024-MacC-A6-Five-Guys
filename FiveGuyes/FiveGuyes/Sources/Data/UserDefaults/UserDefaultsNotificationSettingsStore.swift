//
//  UserDefaultsNotificationSettingsStore.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

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
