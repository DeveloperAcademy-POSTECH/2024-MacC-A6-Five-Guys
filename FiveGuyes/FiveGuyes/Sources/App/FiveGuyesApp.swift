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
        let decision = AppLaunchPolicy.decide(makeLaunchEnvironment())

        if decision.shouldConfigureFirebase {
            FirebaseApp.configure()
        }

        if decision.shouldRequestTracking {
            Task {
                await requestTrackingAuthorization()
            }
        }
        return true
    }

    private func makeLaunchEnvironment() -> AppLaunchPolicy.Environment {
        #if DEBUG
        return AppLaunchPolicy.Environment(
            isDebugBuild: true,
            // 테스트 러너가 호스트 앱에 넣어 주는 키. 값은 빈 문자열이므로 존재 여부만 본다.
            isRunningTests: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil,
            hasFirebaseConfig: Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        )
        #else
        return AppLaunchPolicy.Environment(isDebugBuild: false, isRunningTests: false, hasFirebaseConfig: true)
        #endif
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
