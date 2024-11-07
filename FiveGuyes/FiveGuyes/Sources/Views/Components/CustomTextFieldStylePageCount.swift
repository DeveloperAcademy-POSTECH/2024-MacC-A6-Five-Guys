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
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                            .padding(.leading, 8)
                    }
                   
                }
            Image(systemName: "pencil")
                           .foregroundColor(Color(red: 0.12, green: 0.68, blue: 0.41))
                          
        }.font(.system(size: 20))
            .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.93, green: 0.97, blue: 0.95))
            .cornerRadius(8)
        
    }
}

extension TextField {
    func customStyleFieldPageCount(placeholder: String, text: Binding<String>) -> some View {
        self.modifier(CustomTextFieldStylePageCount(placeholder: placeholder, text: text))
    }
}
