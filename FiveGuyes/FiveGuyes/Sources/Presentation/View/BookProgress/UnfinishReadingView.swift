//
//  UnfinishGoalView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/13/25.
//

import SwiftUI

struct UnfinishReadingView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator

    @State private var viewModel: UnfinishReadingViewModel
    private let userBook: FGUserBook

    // MARK: - init

    init(userBook: FGUserBook, viewModel: UnfinishReadingViewModel) {
        self.userBook = userBook
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            unfinishTitle("목표 기간 종료!")
                .padding(.bottom, 16)

            unFinishDescription("총 \(userBook.readingProgress.lastReadPage) 쪽까지 읽었어요!\n지속적인 노력이 중요하죠")
                .padding(.bottom, 90)

            userBookImage(book: userBook)
                .commonShadow()
                .padding(.bottom, 28)

            unfinishMessage("목표 기간을 연장해서\n남은 페이지를 완독할 수 있어요")
                .padding(.bottom, 80)

            HStack(spacing: 16) {
                cancelButton {
                    Task {
                        await completeAndPopToRoot()
                    }
                }

                readingDateEtidButton {
                    navigationCoordinator.push(.readingDateEdit(book: userBook))
                }
            }
            .padding(.horizontal, 20)

            Spacer()

        }
        .background(Color.Fills.lightGreen.ignoresSafeArea())
        .disableNavigationGesture()
        .customNavigationBackButton {
            markBookAsCompletedInBackground()
        }
    }

    private func unfinishTitle(_ text: String) -> some View {
        Text(text)
            .fontStyle(.body, weight: .semibold)
            .foregroundStyle(.green)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.white)
            }
    }

    private func unFinishDescription(_ text: String) -> some View {
        Text(text)
            .fontStyle(.title1, weight: .semibold)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .multilineTextAlignment(.center)
    }

    private func userBookImage(book: FGUserBook) -> some View {
        Group {
            if let urlString = book.bookMetaData.coverImageURL {
                AsyncImage(url: URL(string: urlString)) { image in
                    image
                        .resizable()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image("")
                    .resizable()
                    .frame(width: 173)
            }
        }
        .scaledToFit()
        .frame(height: 267)
        .clipToBookShape()
    }

    private func unfinishMessage(_ text: String) -> some View {
        Text(text)
            .fontStyle(.caption1)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .multilineTextAlignment(.center)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.white)
            }
    }

    private func readingDateEtidButton(actions: @escaping () -> Void) -> some View {
        Button(action: actions) {
            Text("목표 기간 연장하기")
                .fontStyle(.title2, weight: .semibold)
                .foregroundStyle(Color.Fills.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.Colors.green1)
                }
        }
        .disabled(viewModel.isCompleting)
    }

    private func cancelButton(actions: @escaping () -> Void) -> some View {
        Button(action: actions) {
            Text("닫기")
                .fontStyle(.title2, weight: .semibold)
                .foregroundStyle(Color.Labels.primaryBlack1)
                .frame(width: 107, height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.Fills.white)
                }
        }
        .disabled(viewModel.isCompleting)
    }

    // MARK: - Helper Methods

    @MainActor
    private func completeAndPopToRoot() async {
        let isCompleted = await viewModel.completeBook(userBook)

        if isCompleted {
            navigationCoordinator.popToRoot()
        }
    }

    private func markBookAsCompletedInBackground() {
        Task {
            _ = await viewModel.completeBook(userBook)
        }
    }
}

#if DEBUG
#Preview("기본 상태") {
    let overdueBook = PreviewSupport.makeBook(
        title: "목표 기간이 끝난 도서",
        isCompleted: false,
        lastReadPage: 184
    )
    let binding = PreviewSupport.bindReadingBook(overdueBook)

    NavigationStack {
        UnfinishReadingView(
            userBook: binding.userBook,
            viewModel: UnfinishReadingViewModel(
                bookCompletionUseCase: binding.useCase
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}

#Preview("표지 이미지 있는 상태") {
    let bookWithCover = PreviewSupport.makeBook(
        title: "표지 있는 미완독 도서",
        isCompleted: false,
        coverImageURL: "https://example.com/sample-cover.jpg",
        lastReadPage: 210
    )
    let binding = PreviewSupport.bindReadingBook(bookWithCover)

    NavigationStack {
        UnfinishReadingView(
            userBook: binding.userBook,
            viewModel: UnfinishReadingViewModel(
                bookCompletionUseCase: binding.useCase
            )
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}
#endif
