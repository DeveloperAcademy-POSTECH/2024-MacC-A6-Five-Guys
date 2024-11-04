//
//  CompletionReflectionView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CompletionReflectionView: View {
    private let bookName = "프리웨이"
    private let placeholder: String = "책 속 한 줄이 남긴 여운은 무엇인가요?"
    
    @State private var reflectionText: String = ""
    @FocusState private var isFocusedTextEditor: Bool
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    // TODO: Font, Color 설정
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("<\(bookName)>\(bookName.postPositionParticle()) 완독하고...\n어떤 영감을 얻었나요?")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.black)
                    
                    TextEditor(text: $reflectionText)
                        .customStyleEditor(placeholder: placeholder, userInput: $reflectionText)
                        .frame(height: 222)
                        .focused($isFocusedTextEditor)
                }
                .padding(20)
                
                Spacer()
                
                if keyboardObserver.keyboardIsVisible {
                    Button {
                        print("clicked")
                    } label: {
                        Text("저장")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.green)
                            .foregroundStyle(.white)
                        
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
        .customNavigationBackButton()
        .onAppear {
            isFocusedTextEditor = true
        }
    }
}

#Preview {
    CompletionReflectionView()
}
