//
//  NotificationManager.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/8/24.
//

import UserNotifications

final class NotificationManager {
    private let notificationCenter: UNUserNotificationCenter
    private let todayProvider: any ReadingDateProviding
    private let settingsStore: any NotificationSettingsStoring

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        todayProvider: any ReadingDateProviding = DefaultReadingDateProvider(),
        settingsStore: any NotificationSettingsStoring = UserDefaultsNotificationSettingsStore()
    ) {
        self.notificationCenter = notificationCenter
        self.todayProvider = todayProvider
        self.settingsStore = settingsStore
    }

    /// 모든 노티를 요청하는 메서드
    func canSendNotifications() async -> Bool {
        let isSystemAuthorized = await requestAuthorization()
        let isAppEnabled = !settingsStore.fetchNotificationDisabled()
        return isSystemAuthorized && isAppEnabled
    }

    /// 노티를 요청하는 메서드
    func setupAllNotifications(_ readingBook: FGUserBook) async {
        await self.clearRequests()
        await self.setupNotifications(notificationType: .morning(readingBook: readingBook))
        await self.setupNotifications(notificationType: .night(readingBook: readingBook))
    }

    /// 노티를 요청하는 메서드
    func setupNotifications(notificationType: NotificationType) async {
        if await canSendNotifications() {
            await scheduleReminderNotification(notificationType: notificationType)
        }
    }

    /// Notification 권한 요청 함수
     func requestAuthorization() async -> Bool {
        do {
            try await notificationCenter
                .requestAuthorization(options: [.sound, .badge, .alert])
            return await getCurrentSettings()
        } catch {
            print("❌ NotificationManager/requestAuthorization: \(error.localizedDescription)")
            return false
        }
    }

    /// 요청한 Noticifation을 모두 지우는 함수
    func clearRequests() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// 리마인드(아침) 알림 요청을 삭제 후 재등록
    func updateMorningNotification(for readingBook: FGUserBook) async {
        await updateNotification(notificationType: .morning(readingBook: readingBook))
    }

    /// 알림 요청을 삭제 후 재등록
    private func updateNotification(notificationType: NotificationType) async {
        let identifier = notificationType.identifier()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier]) // 기존 알림 삭제

        guard await canSendNotifications() else {
            return
        }

        await scheduleReminderNotification(notificationType: notificationType) // 새로운 알림 등록
    }

    /// 현재 Notification 권한 설정을 가져오는 함수
     private func getCurrentSettings() async -> Bool {
        let currentSettings = await notificationCenter.notificationSettings()
        let isAuthorized = (currentSettings.authorizationStatus == .authorized)

        return isAuthorized
    }

    private func scheduleReminderNotification(notificationType: NotificationType) async {
        let today = todayProvider.today()
        guard let date = notificationType.dateContent(today: today) else {
            print("❌ NotificationManager: 다음 읽기 날짜가 없어 알림을 생성하지 않습니다.")
            return
        }

        let dateComponents = makeDateComponents(date: date, notificationType)
        let content = makeNotificationContent(notificationType, today: today)

        let identifier = notificationType.identifier()

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("💯 노티 설정 완료")
        } catch {
            print("❌ NotificationManager/schedule: \(error.localizedDescription)")
        }
    }

    private func makeDateComponents(date: Date, _ notificationType: NotificationType) -> DateComponents {
        let calendar = Calendar.app
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let (hour, minute) = notificationType.timeContent(settingsStore: settingsStore)
        print("💯노티 설정: \(date) \(hour): \(minute)")
        return DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    }

    private func makeNotificationContent(
        _ notificationType: NotificationType,
        today: Date
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let (title, body) = notificationType.descriptionContent(today: today)
        content.title = title
        content.body = body

        return content
    }
}

extension NotificationManager: ReadingNotificationScheduling, NotificationManaging {}
