//
//  NotificationManager.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/8/24.
//

import UserNotifications

final class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isGranted: Bool = false
    
    func setupNotifications(notificationType: NotificationType, selectedTime: Date? = nil) async {
        // 확인용 로그
        print("🔔 requestAuthorization 호출됨: \(notificationType)")
        await requestAuthorization()
        
        if isGranted {
            // 확인용 로그
            print("🔔 scheduleReminderNotification 호출됨: \(notificationType)")
            await scheduleReminderNotification(notificationType: notificationType, selectedTime: selectedTime)
        }
    }
    
    /// 요청한 Noticifation을 모두 지우는 함수
    func clearRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("❌노티 취소")
    }
    
    /// Notification 권한 요청 함수
    private func requestAuthorization() async {
        do {
            try await notificationCenter
                .requestAuthorization(options: [.sound, .badge, .alert])
        } catch {
            print("❌ NotificationManager/requestAuthorization: \(error.localizedDescription)")
        }
        
        await getCurrentSettings()
    }
    
    /// 현재 Notification 권한 설정을 가져오는 함수
    private func getCurrentSettings() async {
        let currentSettings = await notificationCenter.notificationSettings()
        
        isGranted = (currentSettings.authorizationStatus == .authorized)
    }

    private func scheduleReminderNotification(notificationType: NotificationType, selectedTime: Date?) async {
        // dateContent가 nil일 경우 알림을 보내지 않음
        guard let date = notificationType.dateContent() else {
            print("❌ NotificationManager: 다음 읽기 날짜가 없어 알림을 생성하지 않습니다.")
            return
        }
        // selectedTime 추가
        let dateComponents = makeDateComponents(date: date, notificationType, selectedTime: selectedTime ?? Date())
        let content = makeNotificationContent(notificationType)
        
        let identifier = notificationType.identifier()
        
        // 설정대로 트리거, 요청 셋팅
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("💯 노티 설정 완료")
        } catch {
            print("❌ NotificationManager/schedule: \(error.localizedDescription)")
        }
    }
    
    private func makeDateComponents(date: Date, _ notificationType: NotificationType, selectedTime: Date?) -> DateComponents {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        // selectedTime 추가
        let (hour, minute) = notificationType.timeContent(selectedTime: selectedTime)
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
    
    // 노티 설정 여부 로그 확인용 프린트 함수
    func printPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            if requests.isEmpty {
                print("❌ 등록된 알림이 없습니다.")
            } else {
                print("✅ 등록된 알림 목록:")
                for request in requests {
                    print("🔔 \(request.identifier): \(request.content.title)")
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        print("  - Trigger Time: \(trigger.dateComponents.hour ?? 0) : \(trigger.dateComponents.minute ?? 0)")
                    }
                }
            }
        }
    }
}
