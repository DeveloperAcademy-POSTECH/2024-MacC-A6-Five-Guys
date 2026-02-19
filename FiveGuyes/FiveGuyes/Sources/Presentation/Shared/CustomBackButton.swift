//
//  CustomBackButton.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

enum BackNavigationMode {
    case pop
    case popToRoot
    case none
}

enum BackSwipePolicy {
    case systemDefault
    case disabled
}

struct CustomBackButton: View {
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    var action: (() -> Void)? // 추가 액션을 위한 옵셔널 클로저
    var backMode: BackNavigationMode = .pop

    var body: some View {
        Button {
            action?() // 액션이 있으면 실행
            switch backMode {
            case .pop:
                _ = navigationCoordinator.pop()
            case .popToRoot:
                _ = navigationCoordinator.popToRoot()
            case .none:
                break
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
    var action: (() -> Void)? // 추가 액션
    var backMode: BackNavigationMode = .pop
    var swipeBackPolicy: BackSwipePolicy = .systemDefault

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CustomBackButton(
                        action: action,
                        backMode: backMode
                    )
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationSwipeBackPolicy(swipeBackPolicy)
    }
}

extension View {
    func customNavigationBackButton(
        action: (() -> Void)? = nil,
        backMode: BackNavigationMode = .pop,
        swipeBackPolicy: BackSwipePolicy = .systemDefault
    ) -> some View {
        self.modifier(
            NavigationBackButtonModifier(
                action: action,
                backMode: backMode,
                swipeBackPolicy: swipeBackPolicy
            )
        )
    }
}

#Preview {
    NavigationStack {
        Color.red
            .customNavigationBackButton()
    }
    .environment(PreviewSupport.makeCoordinator())
}
