//
//  NotificationManaging.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

protocol NotificationManaging {
    func requestAuthorization() async -> Bool
    func clearRequests() async
    func setupAllNotifications(_ readingBook: FGUserBook) async
    func updateNotification(notificationType: NotificationType) async
}
