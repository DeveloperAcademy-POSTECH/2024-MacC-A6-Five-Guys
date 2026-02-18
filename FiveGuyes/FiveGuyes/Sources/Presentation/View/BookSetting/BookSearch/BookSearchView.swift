//
//  BookSearchView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

struct BookSearchView: View {
    private let searchConfigAlertTitle = "검색 설정을 확인해주세요"

    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    @Environment(BookSettingPageModel.self) var pageModel: BookSettingPageModel

    @State private var bookSearchViewModel: BookSearchViewModel

    init(viewModel: BookSearchViewModel) {
        _bookSearchViewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindableViewModel = bookSearchViewModel

        BookListView(bookSearchViewModel: bookSearchViewModel)
            .background(Color.Fills.white)
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            guard let selection = await bookSearchViewModel.completeSelection()
                            else { return }

                            bookSettingInputModel
                                .setPageRange(
                                    end: selection.totalPages
                                )

                            bookSettingInputModel
                                .setSelectedBook(selection.selectedBook)

                            pageModel.nextPage()
                        }

                    } label: {
                        Text("완료")
                            .foregroundStyle((bookSearchViewModel.selectedBook != nil
                                              && !bookSearchViewModel.isCompletingSelection) ?
                                             Color.Colors.green2
                                             : Color.Labels.tertiaryBlack3)
                    }
                    .disabled(bookSearchViewModel.selectedBook == nil
                              || bookSearchViewModel.isCompletingSelection)
                }
            }
            .alert(
                searchConfigAlertTitle,
                isPresented: $bindableViewModel.showSearchConfigAlert
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(bindableViewModel.searchConfigAlertMessage)
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
