//
//  NavigationInteractivePopHost.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/20/26.
//

import SwiftUI
import UIKit

extension View {
    /// 루트 `NavigationStack`에 back 제스처 host를 부착합니다.
    func navigationRootBackHost() -> some View {
        self.background {
            NavigationInteractivePopHost()
        }
    }
}

struct NavigationInteractivePopHost: View {
    @Environment(NavigationCoordinator.self) private var navigationCoordinator

    var body: some View {
        NavigationInteractivePopConfigurator(
            isEnabled: navigationCoordinator.isInteractivePopEnabled
        )
        .frame(width: 0, height: 0)
    }
}

private struct NavigationInteractivePopConfigurator: UIViewControllerRepresentable {
    let isEnabled: Bool

    func makeUIViewController(context: Context) -> NavigationPopHostController {
        let viewController = NavigationPopHostController()
        viewController.isInteractivePopEnabled = isEnabled
        return viewController
    }

    func updateUIViewController(_ uiViewController: NavigationPopHostController, context: Context) {
        uiViewController.isInteractivePopEnabled = isEnabled
    }
}

final class NavigationPopGestureDelegateTracker {
    private weak var savedPopGestureDelegate: UIGestureRecognizerDelegate?
    private weak var managedPopGestureRecognizer: UIGestureRecognizer?
    private var isOverridingPopGestureDelegate = false

    func apply(isEnabled: Bool, to popGestureRecognizer: UIGestureRecognizer) {
        if isEnabled {
            beginOverride(on: popGestureRecognizer)
            popGestureRecognizer.isEnabled = true
        } else {
            restoreIfNeeded(on: popGestureRecognizer)
            popGestureRecognizer.isEnabled = false
        }
    }

    func restoreManagedIfNeeded() {
        restoreIfNeeded(on: managedPopGestureRecognizer)
    }

    private func beginOverride(on popGestureRecognizer: UIGestureRecognizer) {
        if let managedPopGestureRecognizer,
           managedPopGestureRecognizer !== popGestureRecognizer {
            restoreIfNeeded(on: managedPopGestureRecognizer)
        }

        if !isOverridingPopGestureDelegate ||
            managedPopGestureRecognizer !== popGestureRecognizer {
            savedPopGestureDelegate = popGestureRecognizer.delegate
        }

        popGestureRecognizer.delegate = nil
        managedPopGestureRecognizer = popGestureRecognizer
        isOverridingPopGestureDelegate = true
    }

    private func restoreIfNeeded(on popGestureRecognizer: UIGestureRecognizer?) {
        guard isOverridingPopGestureDelegate else {
            clearTracking()
            return
        }

        defer { clearTracking() }

        guard let popGestureRecognizer else {
            return
        }

        // 외부에서 delegate를 재설정했다면 값을 덮어쓰지 않습니다.
        guard popGestureRecognizer.delegate == nil else {
            return
        }

        popGestureRecognizer.delegate = savedPopGestureDelegate
    }

    private func clearTracking() {
        savedPopGestureDelegate = nil
        managedPopGestureRecognizer = nil
        isOverridingPopGestureDelegate = false
    }
}

private final class NavigationPopHostController: UIViewController {
    private let popGestureDelegateTracker = NavigationPopGestureDelegateTracker()

    var isInteractivePopEnabled: Bool = false {
        didSet {
            applyPolicy()
        }
    }

    deinit {
        popGestureDelegateTracker.restoreManagedIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyPolicy()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            popGestureDelegateTracker.restoreManagedIfNeeded()
            return
        }

        applyPolicy()
    }

    private func applyPolicy() {
        guard let navigationController,
              let popGestureRecognizer = navigationController.interactivePopGestureRecognizer else {
            return
        }

        popGestureDelegateTracker.apply(
            isEnabled: isInteractivePopEnabled,
            to: popGestureRecognizer
        )
    }
}
