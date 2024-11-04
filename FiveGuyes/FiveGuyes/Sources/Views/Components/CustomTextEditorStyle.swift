//
//  CustomTextEditorStyle.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CustomTextEditorStyle: ViewModifier {
    let placeholder: String
    @Binding var text: String
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 22)
            .padding(.horizontal, 20)
            .overlay(alignment: .topLeading) {
                placeholderView()
            }
            .textInputAutocapitalization(.none) // 첫 시작 대문자 막기
            .autocorrectionDisabled()
            .background(Color(red: 0.93, green: 0.97, blue: 0.95))
            .opacity(0.8)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scrollContentBackground(.hidden)
            .font(.system(size: 14))
    }
    
    @ViewBuilder
    private func placeholderView() -> some View {
        if text.isEmpty {
            Text(placeholder)
                .padding(.top, 30)
                .padding(.leading, 27)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

extension TextEditor {
    func customStyleEditor(placeholder: String, userInput: Binding<String>) -> some View {
        self.modifier(CustomTextEditorStyle(placeholder: placeholder, text: userInput))
    }
}
