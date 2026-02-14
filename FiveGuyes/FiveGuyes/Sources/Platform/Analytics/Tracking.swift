//
//  Tracking.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/23/24.
//

import FirebaseAnalytics

enum Tracking {
    enum Screen: String {
        // A 그룹: 메인 및 초기 화면
        case splash = "A0_Splash"                   // 스플래시 화면
        case homeBeforeBookSetting = "A1_Home_BeforeBookSetting" // 책 등록 전 메인 홈
        case homeAfterBookSetting = "A2_Home_AfterBookSetting"   // 책 등록 후 메인 홈
        
        // B 그룹: 책 등록 과정
        case bookSearch = "B1_BookSearch"         // 책 검색
        case pageSetting = "B2_PageSetting"          // 페이지 입력
        case dateSelection = "B3_DateSelection"  // 날짜 선택
        case registrationResult = "B4_RegistrationResult" // 최종 결과 화면
        
        // C 그룹: 캘린더 및 기록
        case calendarView = "C1_CalendarView"        // 전체 기록 캘린더
        case dailyProgress = "C2_DailyProgress"     // 오늘 읽은 페이지 기록
        
        // D 그룹: 알림 설정
        case notificationSettings = "D1_NotificationSettings" // 노티 시간 수정 화면
        
        // 트래킹 메서드
        func setTracking() {
            Analytics.logEvent(AnalyticsEventScreenView,
                               parameters: [
                                AnalyticsParameterScreenName: self.rawValue
                               ])
        }
    }
}
