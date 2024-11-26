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
    @Query(filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    // TODO: Font, Color 설정
    var body: some View {
        let userBook = currentlyReadingBooks.first ?? UserBook.dummyUserBookV2
        
        let bookMetadata: BookMetaDataProtocol = userBook.bookMetaData
        var completionStatus: CompletionStatusProtocol = userBook.completionStatus
        let userSettings = userBook.userSettings
        
        let title = bookMetadata.title
        
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("<\(title)>\(title.postPositionParticle()) 완독하고...")
                        Text("어떤 영감을 얻었나요?")
                    }
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.black)
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
                            completionStatus.markAsCompleted(review: reflectionText)
                            
                            // TODO: 해당 로직 모델로 옮기기 🐯
                            userSettings.targetEndDate = Date()
                            if userSettings.startDate > userSettings.targetEndDate {
                                userSettings.startDate = userSettings.targetEndDate
                            }
                            
                            navigationCoordinator.popToRoot()
                        }
                    } label: {
                        Text("저장")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.07, green: 0.87, blue: 0.54))
                            .foregroundStyle(.white)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("내용을 입력해주세요"),
                  dismissButton: .default(Text("확인")))
        }
        .customNavigationBackButton()
        .onAppear {
            isFocusedTextEditor = true
        }
    }
}

#Preview {
    CompletionReviewView()
}
