//
//  NotificationSettingsStoring.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

protocol NotificationSettingsStoring {
    func saveNotificationDisabled(_ isNotificationDisabled: Bool)
    func fetchNotificationDisabled() -> Bool
    func saveNotificationTime(hour: Int, minute: Int)
    func fetchNotificationReminderTime() -> (hour: Int, minute: Int)
}
