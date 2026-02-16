//
//  DailyProgressView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftUI

struct DailyProgressView: View {
    @State private var viewModel: DailyProgressViewModel

    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator

    private let alertText = "전체쪽수를 초과해서 작성했어요!"
    private let alertMessage = "끝까지 읽은 게 맞나요?"

    @FocusState private var isTextTextFieldFocused: Bool

    private let userBook: FGUserBook

    init(userBook: FGUserBook, viewModel: DailyProgressViewModel) {
        self.userBook = userBook
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        let today = viewModel.today()
        let title = userBook.bookMetaData.title
        let targetEndPage = userBook.userSettings.targetEndPage
        let targetEndDate = userBook.userSettings.targetEndDate

        let isTodayCompletionDate = Calendar.app.isDate(today, inSameDayAs: targetEndDate)

        VStack(spacing: 0) {
            HStack {
                Text(isTodayCompletionDate ? "오늘은 <\(title)>\(title.postPositionParticle()) 완독하는\n마지막 날이에요"
                     : "지금까지 읽은 쪽수를\n알려주세요")
                .fontStyle(.title2, weight: .semibold)
                Spacer()
            }
            .padding(.top, 25)
            .padding(.bottom, 107)
            .padding(.horizontal, 20)

            HStack {
                Spacer()

                TextField("", value: $bindableViewModel.pagesToReadToday, format: .number)
                    .frame(width: 180, height: 68)
                    .background(Color.Fills.lightGreen)
                    .cornerRadius(16)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .fontStyle(.title1, weight: .semibold)
                    .tint(Color.Labels.primaryBlack1)
                    .focused($isTextTextFieldFocused)

                Text("쪽")
                    .padding(.top, 20)
                    .fontStyle(.title1, weight: .semibold)
                Spacer()
            }
            .padding(.horizontal, 20)

            Spacer()

            if isTextTextFieldFocused {
                Button {
                    if viewModel.requestSubmit(targetEndPage: targetEndPage) {
                        Task {
                            await submitReading()
                        }
                    }
                } label: {
                    Text("완료")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.Colors.green1)
                        .foregroundStyle(Color.Fills.white)

                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .disabled(viewModel.isSubmitting)
            }

        }
        .alert(isPresented: $bindableViewModel.showTargetExceededAlert) {
            Alert(
                title: Text(alertText)
                    .alertFontStyle(.title3, weight: .semibold),
                message: Text(alertMessage)
                    .alertFontStyle(.caption1),
                primaryButton: .cancel(Text("다시 작성하기")) {
                    viewModel.pagesToReadToday = 0
                    isTextTextFieldFocused = true
                },
                secondaryButton: .default(Text("확인")) {
                    viewModel.applyMaximumTargetPages(targetEndPage)
                    Task {
                        await submitReading()
                    }
                }
            )
        }
        .navigationTitle("오늘 독서 현황 기록하기")
        .customNavigationBackButton()
        .onAppear {
            viewModel.preloadPages(userBook: userBook)
            isTextTextFieldFocused = true
        }
        .onAppear {
            Tracking.Screen.dailyProgress.setTracking()
        }
    }

    @MainActor
    private func submitReading() async {
        switch await viewModel.submit(bookId: userBook.id) {
        case .none:
            return
        case .popToRoot:
            navigationCoordinator.popToRoot()
        case .completionCelebration(let updatedBook):
            navigationCoordinator.push(.completionCelebration(book: updatedBook))
        }
    }
}

#if DEBUG
#Preview("일반 진행 상태") {
    let binding = PreviewSupport.bindReadingBook(PreviewSupport.sampleReadingBook)

    NavigationStack {
        DailyProgressView(
            userBook: binding.userBook,
            viewModel: DailyProgressViewModel(
                dailyReadingUseCase: binding.useCase
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}

#Preview("완독 마감일") {
    let dueTodayBook = PreviewSupport.makeBook(
        title: "오늘 완독 목표 도서",
        isCompleted: false,
        targetEndDateOffset: 0,
        lastReadPage: 300
    )
    let binding = PreviewSupport.bindReadingBook(dueTodayBook)

    NavigationStack {
        DailyProgressView(
            userBook: binding.userBook,
            viewModel: DailyProgressViewModel(
                dailyReadingUseCase: binding.useCase
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}
#endif
