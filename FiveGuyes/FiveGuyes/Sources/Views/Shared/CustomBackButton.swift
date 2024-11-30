//
//  CustomBackButton.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .tint(Color(Color.Labels.primaryBlack1))
                }
            }
            Spacer()
        }
        .background(.white)
    }
}

struct NavigationBackButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: CustomBackButton())
    }
}

extension View {
    func customNavigationBackButton() -> some View {
        self.modifier(NavigationBackButtonModifier())
    }
}

#Preview {
    NavigationStack {
        EmptyView()
            .customNavigationBackButton()
    }
}
