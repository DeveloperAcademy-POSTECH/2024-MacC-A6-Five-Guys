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
                        .foregroundStyle(Color(red: 0.74, green: 0.74, blue: 0.74))
                    )
                    .onSubmit {
                        requestSearchBooks()
                    }
                    .fontStyle(.body)
                    .foregroundStyle(Color(Color.Labels.primaryBlack1))
                    
                    Spacer()
                    
                    Button {
                        requestSearchBooks()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color(red: 0.74, green: 0.74, blue: 0.74))
                            .padding(.leading, 20)
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: -0.5)
                        .stroke(Color(red: 0.94, green: 0.94, blue: 0.94), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                ForEach(bookSearchViewModel.books) { book in
                    BookRowView(viewModel: bookSearchViewModel, book: book)
                }
            }
            .background(.white)
        }
    }
    
    private func requestSearchBooks() {
        Task {
            await bookSearchViewModel.searchBooks(query: searchText)
        }
    }
}

#Preview {
    BookListView(bookSearchViewModel: BookSearchViewModel())
}
