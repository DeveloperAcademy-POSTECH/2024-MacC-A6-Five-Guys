//
//  View+NavigationSwipeBackPolicy.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/19/26.
//

import SwiftUI
import UIKit

extension View {
    /// 네비게이션 드래그 제스처를 비활성화합니다.
    func disableNavigationGesture() -> some View {
        self.navigationSwipeBackPolicy(.disabled)
    }

    /// 네비게이션 swipe back 제스처 정책을 지정합니다.
    func navigationSwipeBackPolicy(_ policy: BackSwipePolicy) -> some View {
        self.background {
            NavigationSwipeBackPolicyConfigurator(policy: policy)
                .frame(width: 0, height: 0)
        }
    }
}

private struct NavigationSwipeBackPolicyConfigurator: UIViewControllerRepresentable {
    let policy: BackSwipePolicy

    func makeUIViewController(context: Context) -> NavigationSwipeBackPolicyViewController {
        let viewController = NavigationSwipeBackPolicyViewController()
        viewController.policy = policy
        return viewController
    }

    func updateUIViewController(_ uiViewController: NavigationSwipeBackPolicyViewController, context: Context) {
        uiViewController.policy = policy
    }
}

private final class NavigationSwipeBackPolicyViewController: UIViewController {
    var policy: BackSwipePolicy = .systemDefault {
        didSet {
            applyPolicy()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyPolicy()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreSystemDefaultPolicy()
    }

    private func applyPolicy() {
        guard let navigationController,
              let popGestureRecognizer = navigationController.interactivePopGestureRecognizer else {
            return
        }

        switch policy {
        case .systemDefault:
            popGestureRecognizer.isEnabled = navigationController.viewControllers.count > 1
        case .disabled:
            popGestureRecognizer.isEnabled = false
        }
    }

    private func restoreSystemDefaultPolicy() {
        guard let navigationController,
              let popGestureRecognizer = navigationController.interactivePopGestureRecognizer else {
            return
        }

        popGestureRecognizer.isEnabled = navigationController.viewControllers.count > 1
    }
}
