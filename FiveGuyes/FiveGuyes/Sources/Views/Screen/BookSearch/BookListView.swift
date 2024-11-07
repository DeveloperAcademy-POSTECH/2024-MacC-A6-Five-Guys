//
//  BookListView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookListView: View {
    @StateObject private var viewModel = BookViewModel()
    @State private var searchText: String = ""
    private let placeholder: String = "어떤 책을 완독하고 싶나요?"
    @FocusState private var isFocusedTextField: Bool
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    @Binding var resetBookmark: Bool
    var onBookmark: (String, Int) -> Void
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                HStack {
                    ZStack(alignment: .leading) {
                        // Custom placeholder
                        if searchText.isEmpty {
                            Text(placeholder)
                                .foregroundColor(Color(red: 0.74, green: 0.74, blue: 0.74))
                                .font(.system(size: 16))
                        }
                        
                        TextField("", text: $searchText, onCommit: {
                            requestSearch()
                        })
                        .font(.system(size: 16))
                        .foregroundColor(.black) // Sets the color of entered text to black
                        .focused($isFocusedTextField)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        requestSearch()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(red: 0.74, green: 0.74, blue: 0.74))
                            .padding(.leading, 20)
                    })
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: -0.5)
                        .stroke(Color(red: 0.94, green: 0.94, blue: 0.94), lineWidth: 1)
                )
                // TODO: - 스캐너기능
                /*
                Button(action: {
                    // 스캔기능
                }, label: {
                    Image("scanner")
                        .foregroundColor(Color(red: 0.74, green: 0.74, blue: 0.74))
                        .frame(width: 28, height: 28, alignment: .center)
                        .padding(.leading, 20)
                })
                 */
            }
        }
        .padding(.horizontal, 20)        
        ScrollView {
            ForEach(viewModel.books) { book in
                BookRowView(book: book, viewModel: viewModel, resetBookmark: $resetBookmark) { title, pageCount in
                    onBookmark(title, pageCount)
                }
            }
        }
        .padding(.top, 40)
    }
    
    // api 를 통해 검색진행
    private func requestSearch() {
        Task {
            await viewModel.searchBooks(query: searchText)
        }
    }
}
