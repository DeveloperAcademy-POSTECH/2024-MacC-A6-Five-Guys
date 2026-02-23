//
//  NavigationInteractivePopHostTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2/23/26.
//

@testable import FiveGuyes
import Testing
import UIKit

@Suite("NavigationInteractivePopHost 테스트")
@MainActor
struct NavigationInteractivePopHostTests {
    @Test("enable 시 기존 delegate를 저장하고 nil로 override")
    func enable_savesDelegateAndOverridesToNil() {
        let tracker = NavigationPopGestureDelegateTracker()
        let gesture = UIGestureRecognizer()
        let originalDelegate = GestureDelegateSpy()
        gesture.delegate = originalDelegate

        tracker.apply(isEnabled: true, to: gesture)

        #expect(gesture.delegate == nil)
        #expect(gesture.isEnabled)
    }

    @Test("disable 시 Host가 저장한 delegate를 복원")
    func disable_restoresSavedDelegate() {
        let tracker = NavigationPopGestureDelegateTracker()
        let gesture = UIGestureRecognizer()
        let originalDelegate = GestureDelegateSpy()
        gesture.delegate = originalDelegate

        tracker.apply(isEnabled: true, to: gesture)
        tracker.apply(isEnabled: false, to: gesture)

        #expect(gesture.delegate === originalDelegate)
        #expect(!gesture.isEnabled)
    }

    @Test("enable/disable 반복에서도 delegate가 유실되지 않음")
    func repeatedToggle_keepsDelegateStable() {
        let tracker = NavigationPopGestureDelegateTracker()
        let gesture = UIGestureRecognizer()
        let originalDelegate = GestureDelegateSpy()
        gesture.delegate = originalDelegate

        for _ in 0..<3 {
            tracker.apply(isEnabled: true, to: gesture)
            #expect(gesture.delegate == nil)

            tracker.apply(isEnabled: false, to: gesture)
            #expect(gesture.delegate === originalDelegate)
            #expect(!gesture.isEnabled)
        }
    }

    @Test("enable 이후 외부에서 delegate를 재설정하면 disable에서 덮어쓰지 않음")
    func disable_doesNotOverrideExternallyAssignedDelegate() {
        let tracker = NavigationPopGestureDelegateTracker()
        let gesture = UIGestureRecognizer()
        let originalDelegate = GestureDelegateSpy()
        let externalDelegate = GestureDelegateSpy()
        gesture.delegate = originalDelegate

        tracker.apply(isEnabled: true, to: gesture)
        gesture.delegate = externalDelegate
        tracker.apply(isEnabled: false, to: gesture)

        #expect(gesture.delegate === externalDelegate)
        #expect(!gesture.isEnabled)
    }

    @Test("Host 해제 경로에서 restoreManagedIfNeeded가 delegate를 안전하게 복원")
    func restoreManagedIfNeeded_restoresDelegate() {
        let tracker = NavigationPopGestureDelegateTracker()
        let gesture = UIGestureRecognizer()
        let originalDelegate = GestureDelegateSpy()
        gesture.delegate = originalDelegate

        tracker.apply(isEnabled: true, to: gesture)
        tracker.restoreManagedIfNeeded()

        #expect(gesture.delegate === originalDelegate)
    }
}

private final class GestureDelegateSpy: NSObject, UIGestureRecognizerDelegate {}
