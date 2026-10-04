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
    @Test("Release는 테스트 여부, plist 유무, 확인 모드에 상관없이 Firebase를 초기화하고 수집 설정은 건드리지 않고 ATT를 요청한다")
    func decide_release_alwaysConfiguresAndRequestsTracking() {
        let flags = [false, true]

        for isRunningTests in flags {
            for hasFirebaseConfig in flags {
                for isAnalyticsDebugRequested in flags {
                    let environment = AppLaunchPolicy.Environment(
                        isDebugBuild: false,
                        isRunningTests: isRunningTests,
                        hasFirebaseConfig: hasFirebaseConfig,
                        isAnalyticsDebugRequested: isAnalyticsDebugRequested
                    )

                    let decision = AppLaunchPolicy.decide(environment)

                    #expect(decision == .init(shouldConfigureFirebase: true, analyticsCollectionOverride: nil, shouldRequestTracking: true))
                }
            }
        }
    }

    @Test(
        "Debug 테스트 실행 중에는 plist 유무와 확인 모드에 상관없이 Firebase 초기화, 수집 설정, ATT 요청을 모두 건너뛴다",
        arguments: [false, true], [false, true]
    )
    func decide_debugWhileTesting_skipsEverything(hasFirebaseConfig: Bool, isAnalyticsDebugRequested: Bool) {
        let environment = AppLaunchPolicy.Environment(
            isDebugBuild: true,
            isRunningTests: true,
            hasFirebaseConfig: hasFirebaseConfig,
            isAnalyticsDebugRequested: isAnalyticsDebugRequested
        )

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: false, analyticsCollectionOverride: nil, shouldRequestTracking: false))
    }

    @Test("Debug 일반 실행에서 plist가 없으면 확인 모드와 상관없이 Firebase 초기화와 수집 설정만 건너뛰고 ATT는 요청한다", arguments: [false, true])
    func decide_debugWithoutPlist_skipsFirebaseButRequestsTracking(isAnalyticsDebugRequested: Bool) {
        let environment = AppLaunchPolicy.Environment(
            isDebugBuild: true,
            isRunningTests: false,
            hasFirebaseConfig: false,
            isAnalyticsDebugRequested: isAnalyticsDebugRequested
        )

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: false, analyticsCollectionOverride: nil, shouldRequestTracking: true))
    }

    @Test("Debug 일반 실행에서 plist가 있고 확인 모드를 켜면 Firebase를 초기화하고 수집을 켠다")
    func decide_debugWithPlistAndDebugRequested_enablesCollection() {
        let environment = AppLaunchPolicy.Environment(
            isDebugBuild: true,
            isRunningTests: false,
            hasFirebaseConfig: true,
            isAnalyticsDebugRequested: true
        )

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: true, analyticsCollectionOverride: true, shouldRequestTracking: true))
    }

    @Test("Debug 일반 실행에서 plist가 있고 확인 모드를 끄면 Firebase를 초기화하고 수집을 명시적으로 끈다")
    func decide_debugWithPlistAndDebugNotRequested_disablesCollection() {
        let environment = AppLaunchPolicy.Environment(
            isDebugBuild: true,
            isRunningTests: false,
            hasFirebaseConfig: true,
            isAnalyticsDebugRequested: false
        )

        let decision = AppLaunchPolicy.decide(environment)

        #expect(decision == .init(shouldConfigureFirebase: true, analyticsCollectionOverride: false, shouldRequestTracking: true))
    }
}
