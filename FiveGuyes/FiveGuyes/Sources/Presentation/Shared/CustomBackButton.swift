//
//  CustomBackButton.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

enum BackNavigationBehavior {
    case pop
    case none
}

struct CustomBackButton: View {
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    var action: (() -> Void)? // 추가 액션을 위한 옵셔널 클로저
    var backBehavior: BackNavigationBehavior = .pop

    var body: some View {
        Button {
            action?() // 액션이 있으면 실행
            if backBehavior == .pop {
                _ = navigationCoordinator.pop()
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
    var backBehavior: BackNavigationBehavior = .pop

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CustomBackButton(
                        action: action,
                        backBehavior: backBehavior
                    )
                }
            }
            .navigationBarBackButtonHidden(true)
    }
}

extension View {
    func customNavigationBackButton(
        action: (() -> Void)? = nil,
        backBehavior: BackNavigationBehavior = .pop
    ) -> some View {
        self.modifier(
            NavigationBackButtonModifier(
                action: action,
                backBehavior: backBehavior
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
