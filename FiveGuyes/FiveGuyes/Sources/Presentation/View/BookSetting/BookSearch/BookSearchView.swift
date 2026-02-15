//
//  BookSearchView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

// TODO: 검색 결과 없을 때 화면 추가하기
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
                // GA4 Tracking
                Tracking.Screen.bookSearch.setTracking()
            }
    }
}

#if DEBUG
// 이 프리뷰는 "선택 전 상태" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("선택 전 상태") {
    // 프리뷰에서 단계 화면을 바로 보여주려고 입력 모델을 먼저 채워 둡니다.
    // 초기값이 있어야 다음 단계 UI를 안정적으로 확인할 수 있습니다.
    let inputModel = PreviewSupport.makeBookSettingInputModel()
    // 원하는 단계 화면을 바로 보려고 페이지 단계를 미리 앞으로 이동시킵니다.
    // 이 값을 맞추면 중간 단계를 매번 반복하지 않아도 됩니다.
    let pageModel = BookSettingPageModel()

    NavigationStack {
        BookSearchView(viewModel: PreviewSupport.makeBookSearchViewModel())
    }
    .environment(inputModel)
    .environment(pageModel)
}

// 이 프리뷰는 "선택 완료 상태" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("선택 완료 상태") {
    // 프리뷰에서 단계 화면을 바로 보여주려고 입력 모델을 먼저 채워 둡니다.
    // 초기값이 있어야 다음 단계 UI를 안정적으로 확인할 수 있습니다.
    let inputModel = PreviewSupport.makeBookSettingInputModel()
    // 원하는 단계 화면을 바로 보려고 페이지 단계를 미리 앞으로 이동시킵니다.
    // 이 값을 맞추면 중간 단계를 매번 반복하지 않아도 됩니다.
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
