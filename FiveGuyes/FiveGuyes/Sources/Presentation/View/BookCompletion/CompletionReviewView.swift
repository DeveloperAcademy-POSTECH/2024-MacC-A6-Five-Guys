//
//  CompletionReviewView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CompletionReviewView: View {
    private let placeholder: String = "책 속 한 줄이 남긴 여운은 무엇인가요?"
    
    @State private var viewModel: CompletionReviewViewModel
    @FocusState private var isFocusedTextEditor: Bool
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    // 업데이트 상황을 나타내는 불 변수
    var isUpdateMode: Bool = false
        
    // 외부에서 주입받을 수 있는 책 변수
    let userBook: FGUserBook

    init(
        isUpdateMode: Bool = false,
        userBook: FGUserBook,
        viewModel: CompletionReviewViewModel
    ) {
        self.isUpdateMode = isUpdateMode
        self.userBook = userBook
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
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
                    
                    TextEditor(text: $bindableViewModel.reflectionText)
                        .customStyleEditor(
                            placeholder: placeholder,
                            userInput: $bindableViewModel.reflectionText
                        )
                        .frame(height: 222)
                        .focused($isFocusedTextEditor)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                if keyboardObserver.keyboardIsVisible {
                    Button {
                        Task {
                            await submitReview()
                        }
                    } label: {
                        Text("저장")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.Colors.green1)
                            .foregroundStyle(Color.Fills.white)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .disabled(viewModel.isSubmitting)
                }
            }
        }
        .alert(isPresented: $bindableViewModel.showEmptyReviewAlert) {
            Alert(title: Text("내용을 입력해주세요")
                .alertFontStyle(.title3, weight: .semibold),
                  dismissButton: .default(Text("확인")))
        }
        .customNavigationBackButton()
        .onAppear {
            viewModel.preloadReview(userBook.completionStatus.reviewAfterCompletion)
            isFocusedTextEditor = true
        }
    }

    @MainActor
    private func submitReview() async {
        let outcome = await viewModel.submit(
            userBookId: userBook.id,
            isUpdateMode: isUpdateMode,
            completionDate: Date().adjustedDate()
        )

        if case .popToRoot = outcome {
            navigationCoordinator.popToRoot()
        }
    }
}

#Preview("완독 소감 작성") {
    NavigationStack {
        CompletionReviewView(
            userBook: PreviewSupport.sampleCompletedBook,
            viewModel: CompletionReviewViewModel(
                bookManagementService: PreviewBookManagementService()
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}

#Preview("완독 소감 수정") {
    let reviewedBook = PreviewSupport.makeBook(
        title: "소감이 있는 도서",
        isCompleted: true,
        reviewAfterCompletion: "이미 남겨둔 완독 소감입니다."
    )

    return NavigationStack {
        CompletionReviewView(
            isUpdateMode: true,
            userBook: reviewedBook,
            viewModel: CompletionReviewViewModel(
                bookManagementService: PreviewBookManagementService(
                    readingBooks: [],
                    completedBooks: [reviewedBook]
                )
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}
