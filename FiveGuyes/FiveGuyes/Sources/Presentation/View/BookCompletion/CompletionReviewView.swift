//
//  CompletionReviewView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftData
import SwiftUI

struct CompletionReviewView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    private let placeholder: String = "책 속 한 줄이 남긴 여운은 무엇인가요?"
    
    @State private var reflectionText: String = ""
    @State private var showAlert = false
    @FocusState private var isFocusedTextEditor: Bool
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    // 업데이트 상황을 나타내는 불 변수
    var isUpdateMode: Bool = false
        
    // 외부에서 주입받을 수 있는 책 변수
    var userBook: UserBook
    
    var body: some View {
        let bookMetadata: BookMetaDataProtocol = userBook.bookMetaData
        var completionStatus: CompletionStatusProtocol = userBook.completionStatus
        let userSettings = userBook.userSettings
        
        let title = bookMetadata.title
        
        ZStack {
            Color.Fills.white.ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("<\(title)>\(title.postPositionParticle()) 완독하고...")
                        Text("어떤 영감을 얻었나요?")
                    }
                    .fontStyle(.title1, weight: .semibold)
                    .foregroundStyle(Color.Labels.primaryBlack1)
                    .lineLimit(1)
                    
                    TextEditor(text: $reflectionText)
                        .customStyleEditor(placeholder: placeholder, userInput: $reflectionText)
                        .frame(height: 222)
                        .focused($isFocusedTextEditor)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                if keyboardObserver.keyboardIsVisible {
                    Button {
                        if reflectionText.isEmpty {
                            showAlert = true
                        } else {
                            
                            if !isUpdateMode {
                                completionStatus.markAsCompleted(review: reflectionText)
                                
                                // TODO: 해당 로직 모델로 옮기기 🐯
                                userSettings.targetEndDate = Date()
                                if userSettings.startDate > userSettings.targetEndDate {
                                    userSettings.startDate = userSettings.targetEndDate
                                }
                            } else {
                                // 업데이트 모드인 경우
                                completionStatus.completionReview = reflectionText
                            }
                            
                            navigationCoordinator.popToRoot()
                        }
                    } label: {
                        Text("저장")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.Colors.green1)
                            .foregroundStyle(Color.Fills.white)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("내용을 입력해주세요")
                .alertFontStyle(.title3, weight: .semibold),
                  dismissButton: .default(Text("확인")))
        }
        .customNavigationBackButton()
        .onAppear {
            reflectionText = completionStatus.completionReview
            isFocusedTextEditor = true
        }
    }
}

//#Preview {
//    CompletionReviewView()
//}
