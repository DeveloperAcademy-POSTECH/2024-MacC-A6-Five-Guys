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

    var isUpdateMode: Bool = false
    var popToRootOnBack: Bool = false

    let userBook: FGUserBook

    init(
        isUpdateMode: Bool = false,
        popToRootOnBack: Bool = false,
        userBook: FGUserBook,
        viewModel: CompletionReviewViewModel
    ) {
        self.isUpdateMode = isUpdateMode
        self.popToRootOnBack = popToRootOnBack
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
        .customNavigationBackButton(
            backMode: popToRootOnBack ? .popToRoot : .pop,
            swipeBackPolicy: popToRootOnBack ? .disabled : .systemDefault
        )
        .onAppear {
            viewModel.preloadReview(userBook.completionStatus.reviewAfterCompletion)
            isFocusedTextEditor = true
        }
    }

    @MainActor
    private func submitReview() async {
        let outcome = await viewModel.submit(
            userBookId: userBook.id,
            isUpdateMode: isUpdateMode
        )

        if case .popToRoot = outcome {
            navigationCoordinator.popToRoot()
        }
    }
}

#if DEBUG
#Preview("완독 소감 작성") {
    let binding = PreviewSupport.bindCompletedBook(PreviewSupport.sampleCompletedBook)

    NavigationStack {
        CompletionReviewView(
            userBook: binding.userBook,
            viewModel: CompletionReviewViewModel(
                bookCompletionUseCase: binding.useCase
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
    let binding = PreviewSupport.bindCompletedBook(reviewedBook)

    NavigationStack {
        CompletionReviewView(
            isUpdateMode: true,
            userBook: binding.userBook,
            viewModel: CompletionReviewViewModel(
                bookCompletionUseCase: binding.useCase
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}
#endif
