//
//  NotificationManaging.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-16.
//

/// OS 알림 권한 상태. 미결정과 거절을 구분해야 배너와 팝업 시점을 정할 수 있다.
enum NotificationAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
}

protocol NotificationManaging {
    /// OS 권한 팝업을 띄우고 그 결과를 반환합니다. 사용자가 알림을 기대하는 시점에만 호출하세요.
    func requestAuthorization() async -> Bool
    /// 현재 OS 권한 상태만 읽습니다. 팝업을 띄우지 않으므로 화면 표시용 조회에 사용하세요.
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func clearRequests() async
    func setupAllNotifications(_ readingBook: FGUserBook) async
    func updateMorningNotification(for readingBook: FGUserBook) async
}
