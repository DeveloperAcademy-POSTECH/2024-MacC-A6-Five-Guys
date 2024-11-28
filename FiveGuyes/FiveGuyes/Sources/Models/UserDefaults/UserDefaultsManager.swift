//
//  UserDefaultsManager.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/28/24.
//

import Foundation

struct UserDefaultsManager {
    enum UserDefaultsKeys: String {
        case isNotificationDisabled  // 시스템 설정이 아닌, 앱 내부에서 관리하는 값
        case reminderHour
        case reminderMinute
    }
    
    /// 노티 권한 여부 저장
    static func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        UserDefaults.standard.set(isNotificationDisabled, forKey: UserDefaultsKeys.isNotificationDisabled.rawValue)
    }
    
    /// 노티 권한 여부 불러오기
    /// 저장 값이 없을 경우 false 리턴
    static func fetchNotificationDisabled() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isNotificationDisabled.rawValue)
    }
    
    /// 시간과 분 저장
      static func saveNotificationTime(hour: Int, minute: Int) {
          UserDefaults.standard.set(hour, forKey: UserDefaultsKeys.reminderHour.rawValue)
          UserDefaults.standard.set(minute, forKey: UserDefaultsKeys.reminderMinute.rawValue)
      }
      
    /// 저장 값이 없을 경우 (9, 0) 리턴 (= 09:00)
    static func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        let hour = UserDefaults.standard.integer(forKey: UserDefaultsKeys.reminderHour.rawValue)
        let minute = UserDefaults.standard.integer(forKey: UserDefaultsKeys.reminderMinute.rawValue)
        return (hour == 0 && minute == 0) ? (9, 0) : (hour, minute)
    }
}
