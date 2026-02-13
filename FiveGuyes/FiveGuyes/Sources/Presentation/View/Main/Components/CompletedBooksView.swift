//
//  CompletedBooksView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftUI

struct CompletedBooksView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @State private var selectedBookIndex: Int = 0
    @State var showCompletionAlert: Bool = false
    
    var completedBooks: [FGUserBook]
    let onDeleteBook: @MainActor (UUID) async -> Bool
    
    let completionAlertMessage = "정말로 내용을 삭제할까요?"
    let completionAlertText = "삭제 후에는 복원할 수 없어요"
    
    var body: some View {
        let completedBooks = Array(completedBooks.reversed())
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("완독 리스트")
                    .fontStyle(.title1, weight: .semibold)
                    .foregroundStyle(Color.Labels.primaryBlack1)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if !completedBooks.isEmpty {
                let safeSelectedIndex = min(selectedBookIndex, completedBooks.count - 1)

                VStack(alignment: .leading, spacing: 16) {
                    // 가로 스크롤로 completedBooks 보여주기
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(completedBooks.indices, id: \.self) { index in
                                let book = completedBooks[index]
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    if let coverURL = book.bookMetaData.coverImageURL, let url = URL(string: coverURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 115, height: 178)
                                                .clipToBookShape()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        Image("bookCoverDummy")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 115, height: 178)
                                            .clipToBookShape()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(book.bookMetaData.title)
                                            .fontStyle(.caption1, weight: .semibold)
                                            .foregroundStyle(Color.Labels.primaryBlack1)
                                        Text(book.bookMetaData.author)
                                            .fontStyle(.caption2)
                                            .foregroundStyle(Color.Labels.secondaryBlack2)
                                    }
                                    .lineLimit(1)
                                }
                                .frame(width: 115)
                                .onTapGesture {
                                    selectedBookIndex = index
                                }
                                .opacity(selectedBookIndex == index ? 1.0 : 0.3)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 선택된 책의 소감문 및 기타 정보 표시
                    let selectedBook = completedBooks[safeSelectedIndex]
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedBook.completionStatus.reviewAfterCompletion)
                            .fontStyle(.body)
                            .foregroundStyle(Color.Labels.primaryBlack1)
                            .padding(.bottom, 10)
                        
                        HStack {
                            Text("\(selectedBook.userSettings.targetEndDate.toKoreanDateStringWithoutYear()) 완독완료")
                            Spacer()
                            
                            Menu {
                                Button {
                                    navigationCoordinator.push(.completionReviewUpdate(book: completedBooks[safeSelectedIndex]))
                                } label: {
                                    Label("내용 수정하기", systemImage: "pencil")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    showCompletionAlert = true
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 22)
                                    .tint(Color.Labels.secondaryBlack2)
                                    .padding(.trailing, 3)

                            }
                        }
                        .fontStyle(.caption2)
                        .foregroundStyle(Color.Labels.secondaryBlack2)
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color.Fills.lightGreen)
                    }
                    .padding(.horizontal, 20)    
                }
                
            } else {
                Rectangle()
                    .frame(width: 115, height: 178)
                    .foregroundStyle(Color.Fills.lightGreen)
                    .padding(.horizontal, 20)
            }
        }
        .alert(isPresented: $showCompletionAlert) {
            Alert(
                title: Text(completionAlertText)
                    .alertFontStyle(.title3, weight: .semibold),
                message: Text(completionAlertMessage)
                    .alertFontStyle(.caption1),
                primaryButton: .cancel(Text("취소하기")),
                secondaryButton: .destructive(Text("삭제")) {
                    let safeSelectedIndex = min(selectedBookIndex, completedBooks.count - 1)
                    let book = completedBooks[safeSelectedIndex]

                    Task {
                        await deleteCompletedBook(id: book.id, currentCount: completedBooks.count)
                    }
                }
            )
        }
    }

    @MainActor
    private func deleteCompletedBook(id: UUID, currentCount: Int) async {
        let deleted = await onDeleteBook(id)
        guard deleted else { return }

        if currentCount <= 1 {
            selectedBookIndex = 0
        } else if selectedBookIndex >= currentCount - 1 {
            selectedBookIndex = currentCount - 2
        }
    }
}

#if DEBUG
#Preview("완독 도서 있음") {
    NavigationStack {
        CompletedBooksView(
            completedBooks: [
                PreviewSupport.sampleCompletedBook,
                PreviewSupport.makeBook(title: "프리뷰 완독 도서 2", isCompleted: true)
            ],
            onDeleteBook: { _ in true }
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}

#Preview("완독 도서 없음") {
    NavigationStack {
        CompletedBooksView(
            completedBooks: [],
            onDeleteBook: { _ in true }
        )
    }
    .environment(PreviewSupport.makeCoordinator())
}
#endif
