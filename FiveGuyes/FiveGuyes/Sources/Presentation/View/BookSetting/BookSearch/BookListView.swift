//
//  BookListView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

// TODO: 검색 완료 시 키보드 내리기
struct BookListView: View {
    @ObservedObject var bookSearchViewModel: BookSearchViewModel
    @State private var searchText: String = ""
    
    private let placeholder: String = "어떤 책을 완독하고 싶나요?"
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    TextField("",
                              text: $searchText,
                              prompt: Text(placeholder)
                        .foregroundStyle(Color.Labels.tertiaryBlack3)
                    )
                    .onSubmit {
                        requestSearchBooks()
                    }
                    .fontStyle(.body)
                    .foregroundStyle(Color.Labels.primaryBlack1)
                    
                    Spacer()
                    
                    Button {
                        requestSearchBooks()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.Labels.quaternaryBlack4)
                            .padding(.leading, 20)
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(Color.Fills.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: -0.5)
                        .stroke(Color.Separators.gray, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                ForEach(bookSearchViewModel.books) { book in
                    BookRowView(viewModel: bookSearchViewModel, book: book)
                }
            }
            .background(Color.Fills.white)
        }
    }
    
    private func requestSearchBooks() {
        Task {
            await bookSearchViewModel.searchBooks(query: searchText)
        }
    }
}

#if DEBUG
// 이 프리뷰는 "검색 결과 없음" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("검색 결과 없음") {
    BookListView(
        bookSearchViewModel: PreviewSupport.makeBookSearchViewModel(books: [])
    )
}

// 이 프리뷰는 "검색 결과 있음" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("검색 결과 있음") {
    BookListView(
        bookSearchViewModel: PreviewSupport.makeBookSearchViewModel(
            books: PreviewSupport.sampleSearchBooks
        )
    )
}
#endif
