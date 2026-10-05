//
//  SystemSettingsManager.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/28/24.
//

import UIKit

struct SystemSettingsManager {
    func openSettings() {
        Self.openSettings()
    }

    /// iOS 설정 앱의 이 앱 알림 설정 화면으로 이동하는 함수
    static func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension SystemSettingsManager: SystemSettingsOpening {}
