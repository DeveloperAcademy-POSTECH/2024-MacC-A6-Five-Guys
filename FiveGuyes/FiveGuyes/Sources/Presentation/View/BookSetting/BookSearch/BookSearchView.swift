//
//  BookSearchView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

struct BookSearchView: View {
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    @Environment(BookSettingPageModel.self) var pageModel: BookSettingPageModel

    @StateObject private var bookSearchViewModel: BookSearchViewModel

    init(viewModel: BookSearchViewModel) {
        _bookSearchViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {

        BookListView(bookSearchViewModel: bookSearchViewModel)
            .background(Color.Fills.white)
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let selectedBook = bookSearchViewModel.selectedBook else { return }

                        Task {
                            let totalPages =  await bookSearchViewModel
                                .fetchBookTotalPages(
                                    isbn: selectedBook.isbn13
                                )

                            bookSettingInputModel
                                .setPageRange(
                                    end: Int(totalPages) ?? 0
                                )

                            bookSettingInputModel
                                .setSelectedBook(selectedBook)

                            pageModel.nextPage()
                        }

                    } label: {
                        Text("완료")
                            .foregroundStyle(bookSearchViewModel.selectedBook != nil ?
                                             Color.Colors.green2
                                             : Color.Labels.tertiaryBlack3)
                    }
                    .disabled(bookSearchViewModel.selectedBook == nil)
                }
            }
            .onAppear {
                Tracking.Screen.bookSearch.setTracking()
            }
    }
}

#if DEBUG
#Preview("선택 전 상태") {
    let inputModel = PreviewSupport.makeBookSettingInputModel()
    let pageModel = BookSettingPageModel()

    NavigationStack {
        BookSearchView(viewModel: PreviewSupport.makeBookSearchViewModel())
    }
    .environment(inputModel)
    .environment(pageModel)
}

#Preview("선택 완료 상태") {
    let inputModel = PreviewSupport.makeBookSettingInputModel()
    let pageModel = BookSettingPageModel()
    let selectedBook = PreviewSupport.sampleSearchBooks.first ?? PreviewSupport.sampleBookSearchItem
    let viewModel = PreviewSupport.makeBookSearchViewModel(
        books: PreviewSupport.sampleSearchBooks,
        selectedBook: selectedBook
    )

    NavigationStack {
        BookSearchView(viewModel: viewModel)
    }
    .environment(inputModel)
    .environment(pageModel)
}
#endif
