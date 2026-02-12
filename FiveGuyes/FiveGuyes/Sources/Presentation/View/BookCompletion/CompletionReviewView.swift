//
//  CompletionReviewView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CompletionReviewView: View {
    private let placeholder: String = "책 속 한 줄이 남긴 여운은 무엇인가요?"
    
    @State private var reflectionText: String = ""
    @State private var showAlert = false
    @State private var isSubmitting = false
    @FocusState private var isFocusedTextEditor: Bool
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(AppDependencies.self) private var appDependencies
    
    // 업데이트 상황을 나타내는 불 변수
    var isUpdateMode: Bool = false
        
    // 외부에서 주입받을 수 있는 책 변수
    let userBook: FGUserBook
    
    var body: some View {
        let title = userBook.bookMetaData.title
        
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
                        submitReview()
                    } label: {
                        Text("저장")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.Colors.green1)
                            .foregroundStyle(Color.Fills.white)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .disabled(isSubmitting)
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
            reflectionText = userBook.completionStatus.reviewAfterCompletion
            isFocusedTextEditor = true
        }
    }

    @MainActor
    private func submitReview() {
        guard !isSubmitting else { return }

        if reflectionText.isEmpty {
            showAlert = true
            return
        }

        isSubmitting = true
        let review = reflectionText

        Task {
            do {
                if isUpdateMode {
                    try await appDependencies.bookManagementService.updateCompletionReview(
                        id: userBook.id,
                        review: review
                    )
                } else {
                    try await appDependencies.bookManagementService.completeBook(
                        id: userBook.id,
                        completionDate: Date().adjustedDate(),
                        review: review
                    )
                }

                await MainActor.run {
                    isSubmitting = false
                    navigationCoordinator.popToRoot()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
                print("완독 소감 저장 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
}

//#Preview {
//    CompletionReviewView()
//}
