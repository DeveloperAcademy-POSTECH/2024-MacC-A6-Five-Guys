//
//  FiveGuyesApp.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/3/24.
//

import AdSupport
import AppTrackingTransparency
import SwiftData
import SwiftUI

import FirebaseCore

@main
struct FiveGuyesApp: App {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    // register app delegate for Firebase setup
      @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationRootView()
                .modelContainer(for: UserBook.self)
        }
    }
}

// MARK: - AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 앱 추적 권한 요청을 비동기적으로 처리
        Task {
            await requestTrackingAuthorization()
        }
        return true
    }
    
    /// 비동기 추적 권한 요청 함수
    private func requestTrackingAuthorization() async {
        // 0.5초 지연 후 추적 권한 요청
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 = 500,000,000 나노초
        } catch {
            print(error)
        }
        
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            let _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }
}
