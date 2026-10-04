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
    @Test("Release는 테스트 여부와 상관없이 Firebase를 초기화하고 ATT를 요청한다", arguments: [false, true])
    func decide_release_alwaysConfiguresAndRequestsTracking(isRunningTests: Bool) {
        let environment = AppLaunchPolicy.Environment(isDebugBuild: false, isRunningTests: isRunningTests)

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: true, shouldRequestTracking: true))
    }

    @Test("Debug 테스트 실행 중에는 Firebase 초기화와 ATT 요청을 모두 건너뛴다")
    func decide_debugWhileTesting_skipsFirebaseAndTracking() {
        let environment = AppLaunchPolicy.Environment(isDebugBuild: true, isRunningTests: true)

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: false, shouldRequestTracking: false))
    }

    @Test("Debug 일반 실행은 Firebase를 초기화하고 ATT를 요청한다")
    func decide_debugNormalLaunch_configuresAndRequestsTracking() {
        let environment = AppLaunchPolicy.Environment(isDebugBuild: true, isRunningTests: false)

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: true, shouldRequestTracking: true))
    }
}
