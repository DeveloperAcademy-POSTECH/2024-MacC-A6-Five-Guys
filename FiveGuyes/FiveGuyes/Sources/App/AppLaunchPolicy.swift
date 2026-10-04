//
//  AppLaunchPolicy.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-10-04.
//

/// 앱 시작 시 Firebase 초기화와 ATT 요청 여부를 정하는 순수 판단 로직.
/// Firebase나 UIKit에 의존하지 않으므로 테스트에서 그대로 사용할 수 있다.
struct AppLaunchPolicy {
    struct Environment {
        /// 호출부에서 `#if DEBUG`로 채운다.
        let isDebugBuild: Bool
        /// 테스트 호스트로 실행됐는지 (`XCTestConfigurationFilePath` 환경변수 존재 여부).
        let isRunningTests: Bool
        /// 번들에 `GoogleService-Info.plist`가 있는지.
        let hasFirebaseConfig: Bool
    }

    struct Decision: Equatable {
        let shouldConfigureFirebase: Bool
        let shouldRequestTracking: Bool
    }

    static func decide(_ environment: Environment) -> Decision {
        // Release에서는 테스트 여부를 보지 않고 항상 기존 동작을 유지한다.
        guard environment.isDebugBuild else {
            return Decision(shouldConfigureFirebase: true, shouldRequestTracking: true)
        }

        // 테스트 호스트 실행 중에는 Firebase와 시스템 팝업(ATT)을 건드리지 않는다.
        if environment.isRunningTests {
            return Decision(shouldConfigureFirebase: false, shouldRequestTracking: false)
        }

        // plist가 없으면 `FirebaseApp.configure()`가 크래시하므로 초기화를 건너뛴다.
        return Decision(shouldConfigureFirebase: environment.hasFirebaseConfig, shouldRequestTracking: true)
    }
}
