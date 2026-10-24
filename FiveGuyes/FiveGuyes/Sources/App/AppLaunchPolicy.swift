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
        /// GA 확인 모드(실행 인자 `-FIRDebugEnabled`)가 요청됐는지.
        let isAnalyticsDebugRequested: Bool
    }

    struct Decision: Equatable {
        let shouldConfigureFirebase: Bool
        /// nil이면 수집 설정을 건드리지 않는다.
        let analyticsCollectionOverride: Bool?
        let shouldRequestTracking: Bool
    }

    static func decide(_ environment: Environment) -> Decision {
        // Release에서는 테스트 여부를 보지 않고 항상 기존 동작을 유지한다.
        guard environment.isDebugBuild else {
            return Decision(shouldConfigureFirebase: true, analyticsCollectionOverride: nil, shouldRequestTracking: true)
        }

        // 테스트 호스트 실행 중에는 Firebase와 시스템 팝업(ATT)을 건드리지 않는다.
        if environment.isRunningTests {
            return Decision(shouldConfigureFirebase: false, analyticsCollectionOverride: nil, shouldRequestTracking: false)
        }

        // plist가 없으면 `FirebaseApp.configure()`가 크래시하므로 초기화를 건너뛴다. 초기화하지 않았으니 수집 설정도 건드리지 않는다.
        guard environment.hasFirebaseConfig else {
            return Decision(shouldConfigureFirebase: false, analyticsCollectionOverride: nil, shouldRequestTracking: true)
        }

        // Debug 수집은 GA 확인 모드일 때만 켠다. 설정값이 실행 간에 유지되므로 끄는 쪽도 매번 명시한다.
        return Decision(
            shouldConfigureFirebase: true,
            analyticsCollectionOverride: environment.isAnalyticsDebugRequested,
            shouldRequestTracking: true
        )
    }
}
