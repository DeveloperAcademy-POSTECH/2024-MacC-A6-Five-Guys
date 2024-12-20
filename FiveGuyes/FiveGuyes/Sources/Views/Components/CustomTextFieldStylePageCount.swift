//
//  CustomTextFieldStylePageCount.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/6/24.
//

import SwiftUI

// TODO: 폰트, 컬러 수정하기
struct CustomTextFieldStylePageCount: ViewModifier {
    let placeholder: String
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
                .overlay(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(Color.Labels.tertiaryBlack3) // TODO: .gray 여서 다른 textfiled 의 placeholder 색상과 맞춤
                            .fontStyle(.title2, weight: .semibold) // TODO: 디자이너 확인 중
                            .padding(.leading, 8)
                    }
                   
                }
            Image(systemName: "pencil")
                .foregroundStyle(Color.Colors.green2)
                          
        }.fontStyle(.title2, weight: .semibold)
            .foregroundStyle(Color.Colors.green2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.Fills.lightGreen)
            .cornerRadius(8)
        
    }
}

extension TextField {
    func customStyleFieldPageCount(placeholder: String, text: Binding<String>) -> some View {
        self.modifier(CustomTextFieldStylePageCount(placeholder: placeholder, text: text))
    }
}
