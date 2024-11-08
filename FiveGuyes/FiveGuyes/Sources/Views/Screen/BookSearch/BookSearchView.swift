//
//  BookSearchView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

struct BookSearchView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @StateObject private var bookSearchViewModel = BookSearchViewModel()
    
    @State private var progress: CGFloat = 0.25
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressBar(progress: progress)
            
            BookListView(bookSearchViewModel: bookSearchViewModel)
        }
        .customNavigationBackButton()
        .navigationTitle("완독할 책 추가하기")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        guard let selectedBook = bookSearchViewModel.selectedBook else { return }
                        
                        let totalPages = await bookSearchViewModel.fetchBookTotalPages(isbn: selectedBook.isbn13)
                        
                        navigationCoordinator.push(.bookPageSetting(selectedBook: selectedBook, totalPages: totalPages))
                    }
                } label: {
                    Text("확인")
                        .foregroundColor(bookSearchViewModel.selectedBook != nil ?
                                         Color(red: 0.03, green: 0.68, blue: 0.41) 
                                         : Color(red: 0.84, green: 0.84, blue: 0.84))
                }
                .disabled(bookSearchViewModel.selectedBook == nil)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NavigationLink("Aa") {
            BookSearchView()
        }
    }
}
