//
//  CustomBackButton.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    var action: (() -> Void)? // 추가 액션을 위한 옵셔널 클로저
    
    var body: some View {
        HStack {
            Button {
                action?() // 액션이 있으면 실행
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .tint(Color.Labels.primaryBlack1)
                }
            }
            Spacer()
        }
        .background(Color.clear)
    }
}

struct NavigationBackButtonModifier: ViewModifier {
    var action: (() -> Void)? // 추가 액션
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: CustomBackButton(action: action))
    }
}

extension View {
    func customNavigationBackButton(action: (() -> Void)? = nil) -> some View {
        self.modifier(NavigationBackButtonModifier(action: action))
    }
}

#Preview {
    NavigationStack {
        EmptyView()
            .customNavigationBackButton()
    }
}
