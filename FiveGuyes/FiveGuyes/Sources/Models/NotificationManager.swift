//
//  NotificationManager.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/8/24.
//

import UserNotifications

final class NotificationManager {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// 알림을 보낼 수 있는지 확인
    private func canSendNotifications() async -> Bool {
        let isSystemAuthorized = await requestAuthorization()
        let isAppEnabled = !UserDefaultsManager.fetchNotificationDisabled()
        return isSystemAuthorized && isAppEnabled
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
    
    /// 알림 요청을 삭제 후 재등록
    func updateNotification(notificationType: NotificationType) async {
        let identifier = notificationType.identifier()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier]) // 기존 알림 삭제
        await scheduleReminderNotification(notificationType: notificationType) // 새로운 알림 등록
    }
    
    /// 현재 Notification 권한 설정을 가져오는 함수
     private func getCurrentSettings() async -> Bool {
        let currentSettings = await notificationCenter.notificationSettings()
        let isAuthorized = (currentSettings.authorizationStatus == .authorized)
        
        return isAuthorized
    }
    
    private func scheduleReminderNotification(notificationType: NotificationType) async {
        // dateContent가 nil일 경우 알림을 보내지 않음
        guard let date = notificationType.dateContent() else {
            print("❌ NotificationManager: 다음 읽기 날짜가 없어 알림을 생성하지 않습니다.")
            return
        }
        
        let dateComponents = makeDateComponents(date: date, notificationType)
        let content = makeNotificationContent(notificationType)
        
        let identifier = notificationType.identifier()
        
        // 설정대로 트리거, 요청 셋팅
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
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let (hour, minute) = notificationType.timeContent()
        print("💯노티 설정: \(date) \(hour): \(minute)")
        return DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    }
    
    private func makeNotificationContent(_ notificationType: NotificationType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let (title, body) = notificationType.descriptionContent()
        content.title = title
        content.body = body
        
        return content
    }
}
