//
//  AppLaunchPolicyTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2026-10-04.
//

@testable import FiveGuyes
import Testing

@Suite("AppLaunchPolicy 테스트")
struct AppLaunchPolicyTests {
    @Test(
        "Release는 테스트 여부와 plist 유무에 상관없이 Firebase를 초기화하고 ATT를 요청한다",
        arguments: [false, true], [false, true]
    )
    func decide_release_alwaysConfiguresAndRequestsTracking(isRunningTests: Bool, hasFirebaseConfig: Bool) {
        let environment = AppLaunchPolicy.Environment(
            isDebugBuild: false,
            isRunningTests: isRunningTests,
            hasFirebaseConfig: hasFirebaseConfig
        )

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: true, shouldRequestTracking: true))
    }

    @Test("Debug 테스트 실행 중에는 plist 유무와 상관없이 Firebase 초기화와 ATT 요청을 모두 건너뛴다", arguments: [false, true])
    func decide_debugWhileTesting_skipsFirebaseAndTracking(hasFirebaseConfig: Bool) {
        let environment = AppLaunchPolicy.Environment(
            isDebugBuild: true,
            isRunningTests: true,
            hasFirebaseConfig: hasFirebaseConfig
        )

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: false, shouldRequestTracking: false))
    }

    @Test("Debug 일반 실행에서 plist가 없으면 Firebase 초기화만 건너뛰고 ATT는 요청한다")
    func decide_debugWithoutPlist_skipsFirebaseButRequestsTracking() {
        let environment = AppLaunchPolicy.Environment(isDebugBuild: true, isRunningTests: false, hasFirebaseConfig: false)

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: false, shouldRequestTracking: true))
    }

    @Test("Debug 일반 실행에서 plist가 있으면 Firebase를 초기화하고 ATT를 요청한다")
    func decide_debugWithPlist_configuresAndRequestsTracking() {
        let environment = AppLaunchPolicy.Environment(isDebugBuild: true, isRunningTests: false, hasFirebaseConfig: true)

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: true, shouldRequestTracking: true))
    }
}
