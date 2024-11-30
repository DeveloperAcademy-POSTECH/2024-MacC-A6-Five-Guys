//
//  BookSearchView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

// TODO: 검색 결과 없을 때 화면 추가하기
struct BookSearchView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @StateObject private var bookSearchViewModel = BookSearchViewModel()
    
    @State private var progress: CGFloat = 0.25
    
    var body: some View {
        
        BookListView(bookSearchViewModel: bookSearchViewModel)
            .background(.white)
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let selectedBook = bookSearchViewModel.selectedBook else { return }
                        
                        Task {
                            bookSettingInputModel.targetEndPage =  await bookSearchViewModel.fetchBookTotalPages(isbn: selectedBook.isbn13)
                            
                            bookSettingInputModel.selectedBook = selectedBook
                            bookSettingInputModel.nextPage()
                        }
                        
                    } label: {
                        Text("완료")
                            .foregroundColor(bookSearchViewModel.selectedBook != nil ?
                                             Color(Color.Colors.green2)
                                             : Color(Color.Labels.tertiaryBlack3))
                    }
                    .disabled(bookSearchViewModel.selectedBook == nil)
                }
            }
            .onAppear {
                // GA4 Tracking
                Tracking.Screen.bookSearch.setTracking()
            }
    }
}
