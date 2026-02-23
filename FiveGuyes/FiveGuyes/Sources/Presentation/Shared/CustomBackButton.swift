//
//  CustomBackButton.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(NavigationCoordinator.self) private var navigationCoordinator

    var body: some View {
        Button {
            Task {
                _ = await navigationCoordinator.handleBackButtonTap()
            }
        } label: {
            Image(systemName: "chevron.left")
                .resizable()
                .scaledToFit()
                .tint(Color.Labels.primaryBlack1)
        }
    }
}

struct NavigationBackButtonModifier: ViewModifier {
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var hookOwner = UUID()

    let routeKey: ScreenRouteKey?
    let beforeBackAction: (() async -> BackDecision)?
    let onStepPopExitAction: (() async -> Void)?

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if navigationCoordinator.effectiveTopPolicy.showsBackButton {
                    ToolbarItem(placement: .cancellationAction) {
                        CustomBackButton()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                syncBackHooks()
            }
            .onDisappear {
                navigationCoordinator.clearTopBackHooks(owner: hookOwner)
            }
    }

    private func syncBackHooks() {
        guard let routeKey else {
            navigationCoordinator.clearTopBackHooks(owner: hookOwner)
            return
        }

        navigationCoordinator.setTopBackHooks(
            owner: hookOwner,
            routeKey: routeKey,
            beforeBackAction: beforeBackAction,
            onStepPopExitAction: onStepPopExitAction
        )
    }
}

extension View {
    /// `NavigationCoordinator`의 중앙 정책을 따라 커스텀 백버튼을 붙입니다.
    ///
    /// 실제 back 동작과 버튼 노출 여부는 런타임의
    /// `effectiveTopPolicy`에서 결정됩니다.
    func customNavigationBackButton(
        routeKey: ScreenRouteKey? = nil,
        beforeBackAction: (() async -> BackDecision)? = nil,
        onStepPopExitAction: (() async -> Void)? = nil
    ) -> some View {
        self.modifier(
            NavigationBackButtonModifier(
                routeKey: routeKey,
                beforeBackAction: beforeBackAction,
                onStepPopExitAction: onStepPopExitAction
            )
        )
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        Color.red
            .customNavigationBackButton()
    }
    .environment(PreviewSupport.makeCoordinator())
}
#endif
