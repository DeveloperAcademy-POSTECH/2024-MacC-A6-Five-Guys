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
    @State private var searchButtonClicked: Bool = false
    private let placeholder: String = "어떤 책을 완독하고 싶나요?"
    
    var body: some View {
        
        VStack(spacing: 40) {
            
            VStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    TextField("",
                              text: $searchText,
                              prompt: Text(placeholder)
                        .foregroundColor(Color(red: 0.74, green: 0.74, blue: 0.74))
                    )
                    .onSubmit {
                        requestSearchBooks()
                        self.searchButtonClicked = true
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button {
                        requestSearchBooks()
                        self.searchButtonClicked = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(red: 0.74, green: 0.74, blue: 0.74))
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
                if searchButtonClicked {
                    // 응답을 요청함
                    if bookSearchViewModel.isLoading {
                        // 기다리는 중
                        // 스켈레톤 UI 등으로 추후에 구현
                    }
                    else {
                        // 응답요청이 어쨌든 끝남
                        if bookSearchViewModel.books.isEmpty {
                            // 값이 없음
                            Text("검색 결과가 없어요!\n검색어를 다시 확인해주세요")
                                .font(Font.custom("Pretendard Variable", size: 14))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
                                .frame(width: 193, alignment: .top)
                        }
                        else {
                            // 값이 있음
                            ForEach(bookSearchViewModel.books) { book in
                                BookRowView(viewModel: bookSearchViewModel, book: book)
                            } .background(.white)
                        }
                    }
                }
                else {
                    // 빈화면 혹은 재검색의 경우 이전화면이 유지됨
                    // (검색어를 입력중이며 버튼클릭등의 요청은 하지 않은 상태)
                }
            }
            
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
