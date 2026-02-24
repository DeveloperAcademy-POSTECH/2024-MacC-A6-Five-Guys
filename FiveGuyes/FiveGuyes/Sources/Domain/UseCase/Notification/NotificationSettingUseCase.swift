//
//  NotificationSettingUseCase.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/16/26.
//

import Foundation

struct NotificationSettingSnapshot {
    let selectedTime: Date
    let isNotificationDisabled: Bool
}

protocol NotificationSettingUsing {
    func loadSnapshot(now: Date) -> NotificationSettingSnapshot
    func refreshSystemAuthorization() async -> Bool
    func setNotificationDisabled(_ isDisabled: Bool, userBook: FGUserBook?) async
    func updateReminderTime(
        _ time: Date,
        isNotificationDisabled: Bool,
        userBook: FGUserBook?
    ) async
    func openSystemSettings()
}

struct NotificationSettingUseCase: NotificationSettingUsing {
    private let notificationService: any NotificationManaging
    private let systemSettingsOpener: any SystemSettingsOpening
    private let settingsStore: any NotificationSettingsStoring

    init(
        notificationService: any NotificationManaging,
        systemSettingsOpener: any SystemSettingsOpening,
        settingsStore: any NotificationSettingsStoring
    ) {
        self.notificationService = notificationService
        self.systemSettingsOpener = systemSettingsOpener
        self.settingsStore = settingsStore
    }

    func loadSnapshot(now: Date) -> NotificationSettingSnapshot {
        let calendar = Calendar.app
        let (hour, minute) = settingsStore.fetchNotificationReminderTime()
        let selectedTime = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now
        ) ?? now

        return NotificationSettingSnapshot(
            selectedTime: selectedTime,
            isNotificationDisabled: settingsStore.fetchNotificationDisabled()
        )
    }

    func refreshSystemAuthorization() async -> Bool {
        await notificationService.requestAuthorization()
    }

    func setNotificationDisabled(_ isDisabled: Bool, userBook: FGUserBook?) async {
        settingsStore.saveNotificationDisabled(isDisabled)

        guard let userBook else { return }

        if isDisabled {
            await notificationService.clearRequests()
        } else {
            await notificationService.setupAllNotifications(userBook)
        }
    }

    func updateReminderTime(
        _ time: Date,
        isNotificationDisabled: Bool,
        userBook: FGUserBook?
    ) async {
        saveNotificationTime(time)

        guard !isNotificationDisabled, let userBook else { return }
        await notificationService.updateMorningNotification(for: userBook)
    }

    func openSystemSettings() {
        systemSettingsOpener.openSettings()
    }

    private func saveNotificationTime(_ time: Date) {
        let calendar = Calendar.app
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        settingsStore.saveNotificationTime(hour: hour, minute: minute)
    }
}
