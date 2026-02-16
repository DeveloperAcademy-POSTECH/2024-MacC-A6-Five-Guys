//
//  CompletionCelebrationView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CompletionCelebrationView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator

    let userBook: FGUserBook
    let viewModel: CompletionCelebrationViewModel

    private let celebrationTitleText = "완독 완료!"
    private let celebrationMessageText = "한 권을 전부 읽다니...\n대단한걸요?"

    var body: some View {
        let summary = viewModel.summary(for: userBook)
        let bookMetadata = userBook.bookMetaData

        VStack(spacing: 0) {
            Spacer()
            celebrationTitle
                .padding(.bottom, 14)

            celebrationMessage
                .padding(.bottom, 80)

            celebrationBookImage(bookMetadata)
                .padding(.bottom, 28)

            readingSummary(summary: summary)

            Spacer()

            reflectionButton
                .padding(.bottom, 21)
        }
        .padding(.horizontal, 16)
        .background {
            Image("completionBackground")
                .ignoresSafeArea()
        }
        .customNavigationBackButton()
    }

    private var celebrationTitle: some View {
        Text(celebrationTitleText)
            .fontStyle(.body, weight: .semibold)
            .foregroundStyle(.green)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.white)
            }
    }

    private var celebrationMessage: some View {
        Text(celebrationMessageText)
            .fontStyle(.title1, weight: .semibold)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .multilineTextAlignment(.center)
    }

    private func celebrationBookImage(_ bookMetadata: FGBookMetaData) -> some View {
        let overlayImage = Image("CompletedWandoki")
            .resizable()
            .scaledToFit()
            .frame(height: 89)
            .offset(y: -72)

        return Group {
            if let coverURL = bookMetadata.coverImageURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image("")
                    .resizable()
            }
        }
        .scaledToFill()
        .frame(width: 173, height: 267)
        .overlay(alignment: .top) {
            overlayImage
        }
    }

    private func readingSummary(summary: CompletionCelebrationSummary) -> some View {
        let startDateText = summary.startDate.toKoreanDateString()
        let endDateText = summary.endDate.toKoreanDateString()

        return Text("\(startDateText)부터 \(endDateText)까지\n꾸준히 \(summary.pagesPerDay)쪽씩 \(summary.totalReadingDays)일동안 읽었어요 🎉")
            .fontStyle(.caption1)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.white)
            }
    }

    private var reflectionButton: some View {
        Button {
            navigationCoordinator.push(.completionReview(book: userBook))
        } label: {
            Text("완독 소감 작성하기")
                .fontStyle(.title2, weight: .semibold)
                .foregroundStyle(Color.Fills.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.Colors.green1)
                }
        }
    }
}

#if DEBUG
#Preview("기본 완독 축하") {
    let dependencies = PreviewSupport.makeDependencies()

    NavigationStack {
        CompletionCelebrationView(
            userBook: PreviewSupport.sampleCompletedBook,
            viewModel: CompletionCelebrationViewModel(
                bookCompletionUseCase: dependencies.bookCompletionUseCase
            )
        )
    }
    .environment(NavigationCoordinator(appDependencies: dependencies))
}

#Preview("표지 이미지 있는 완독") {
    let dependencies = PreviewSupport.makeDependencies()
    let completedWithCover = PreviewSupport.makeBook(
        title: "표지가 있는 도서",
        isCompleted: true,
        coverImageURL: "https://example.com/sample-cover.jpg"
    )

    NavigationStack {
        CompletionCelebrationView(
            userBook: completedWithCover,
            viewModel: CompletionCelebrationViewModel(
                bookCompletionUseCase: dependencies.bookCompletionUseCase
            )
        )
    }
    .environment(NavigationCoordinator(appDependencies: dependencies))
}
#endif
