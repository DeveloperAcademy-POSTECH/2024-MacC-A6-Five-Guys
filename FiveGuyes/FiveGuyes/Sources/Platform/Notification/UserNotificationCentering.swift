//
//  UserNotificationCentering.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-09-20.
//

import UserNotifications

/// NotificationManager가 실제로 사용하는 UNUserNotificationCenter API만 담은 프로토콜.
/// 테스트에서 대역을 주입할 수 있도록 추상화합니다.
protocol UserNotificationCentering {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
}

extension UNUserNotificationCenter: UserNotificationCentering {
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}
