//
//  SystemSettingsManager.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/28/24.
//

import UIKit

struct SystemSettingsManager {
    /// 시스템 설정으로 이동하는 함수
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
