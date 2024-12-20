//
//  CustomTextEditorStyle.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

// TODO: 폰트, 컬러 수정하기
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
            .background(Color.Fills.lightGreen)
            .opacity(0.8)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scrollContentBackground(.hidden)
            .fontStyle(.body) // 수정 적용
    }
    
    @ViewBuilder
    private func placeholderView() -> some View {
        if text.isEmpty {
            Text(placeholder)
                .padding(.top, 30)
                .padding(.leading, 27)
                .fontStyle(.body) // 수정 적용
                .foregroundStyle(Color.Labels.tertiaryBlack3)
        }
    }
}

extension TextEditor {
    func customStyleEditor(placeholder: String, userInput: Binding<String>) -> some View {
        self.modifier(CustomTextEditorStyle(placeholder: placeholder, text: userInput))
    }
}
