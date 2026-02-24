//
//  NotiSettingViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotiSettingViewModel {
    var selectedTime: Date = Date()
    var isNotificationDisabled = false
    var isReminderTimePickerVisible = false
    var isSystemNotificationEnabled = true

    private var notificationStatusTask: Task<Void, Never>?
    private var notificationTimeTask: Task<Void, Never>?

    private let notificationSettingUseCase: any NotificationSettingUsing
    private let nowProvider: () -> Date

    init(
        notificationSettingUseCase: any NotificationSettingUsing,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.notificationSettingUseCase = notificationSettingUseCase
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
        let snapshot = notificationSettingUseCase.loadSnapshot(now: nowProvider())
        selectedTime = snapshot.selectedTime
        isNotificationDisabled = snapshot.isNotificationDisabled
    }

    func refreshSystemNotificationAuthorization() async {
        isSystemNotificationEnabled = await notificationSettingUseCase.refreshSystemAuthorization()
    }

    func handleNotificationStatusChange(userBook: FGUserBook?) {
        notificationStatusTask?.cancel()
        let isDisabled = isNotificationDisabled

        notificationStatusTask = Task {
            guard !Task.isCancelled else { return }
            await notificationSettingUseCase.setNotificationDisabled(isDisabled, userBook: userBook)
        }
    }

    func handleNotificationTimeChange(userBook: FGUserBook?) {
        notificationTimeTask?.cancel()
        let currentSelectedTime = selectedTime
        let isDisabled = isNotificationDisabled

        notificationTimeTask = Task {
            guard !Task.isCancelled else { return }
            await notificationSettingUseCase.updateReminderTime(
                currentSelectedTime,
                isNotificationDisabled: isDisabled,
                userBook: userBook
            )
        }
    }

    func openSystemSettings() {
        notificationSettingUseCase.openSystemSettings()
    }
}
