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

@MainActor
@main
struct FiveGuyesApp: App {
    typealias SDUserBook = UserBookSchemaV2.UserBookV2

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var container: ModelContainer
    @State private var dependencies: AppDependencies

    init() {
        do {
            let modelContainer = try ModelContainer(for: SDUserBook.self)
            self.container = modelContainer
            _dependencies = State(initialValue: AppDependencies(modelContainer: modelContainer))
        } catch {
            fatalError("Failed to initialize model container.")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationRootView(appDependencies: dependencies)
                .environment(dependencies)
                .modelContainer(container)
        }
    }
}

// MARK: - AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Debug에서는 GoogleService-Info.plist가 없으면 Firebase 초기화를 건너뜁니다.
        // plist는 gitignore 대상이라 CI와 자격증명 없는 로컬 환경에는 존재하지 않고,
        // 그대로 configure()를 부르면 앱이 launch 중 abort해 테스트도 실행되지 않습니다.
        // Release에서는 plist 누락이 배포 사고이므로 기존대로 크래시로 드러냅니다.
        #if DEBUG
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        #else
        FirebaseApp.configure()
        #endif

        Task {
            await requestTrackingAuthorization()
        }
        return true
    }

    /// 비동기 추적 권한 요청 함수
    private func requestTrackingAuthorization() async {
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 = 500,000,000 나노초
        } catch {
            print(error)
        }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            await ATTrackingManager.requestTrackingAuthorization()
        }
    }
}
