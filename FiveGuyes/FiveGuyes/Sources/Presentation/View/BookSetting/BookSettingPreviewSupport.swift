//
//  BookSettingPreviewSupport.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
import Foundation

// 화면 값은 메인 스레드에서만 바꿔야 안전합니다.
// 이 표시를 붙여, 다른 스레드가 끼어들어 상태가 꼬이는 일을 막습니다.
@MainActor
extension PreviewSupport {
    static var sampleBookSearchItem: BookSearchItem { makeBookSearchItem(title: "샘플 완독 도서") }

    // 검색 결과에 쓸 도서 샘플을 한 줄로 만들기 위한 함수입니다.
    // 여기로 모아두면 여러 프리뷰가 같은 형태를 재사용할 수 있습니다.
    static func makeBookSearchItem(
        title: String,
        author: String = "한입독서 팀",
        cover: String? = nil,
        publisher: String = "Five Guys Press",
        isbn13: String = "9781234567890",
        pubDate: String = "20250101"
    ) -> BookSearchItem {
        BookSearchItem(
            title: title,
            author: author,
            cover: cover,
            publisher: publisher,
            isbn13: isbn13,
            pubDate: pubDate
        )
    }

    static var sampleSearchBooks: [BookSearchItem] {
        [
            sampleBookSearchItem,
            makeBookSearchItem(
                title: "두 번째 샘플 도서",
                author: "홍길동",
                publisher: "Sample House",
                isbn13: "9781234567891",
                pubDate: "20240220"
            )
        ]
    }

    // 도서 설정 화면이 바로 열리도록 필수 값들을 미리 채웁니다.
    // 매번 손으로 입력하지 않아도 분기 화면을 빠르게 확인할 수 있습니다.
    static func makeBookSettingInputModel() -> BookSettingInputModel {
        let model = BookSettingInputModel()
        // 계산 기준이 흔들리지 않게 오늘 날짜를 먼저 고정합니다.
        // 기준이 매번 바뀌면 같은 프리뷰가 다르게 보여 디버깅이 어려워집니다.
        let today = DefaultReadingDateProvider().today()
        // 시작 날짜를 명확히 정해 둡니다.
        // 그래야 이후 페이지 계산과 캘린더 표시가 같은 기준으로 움직입니다.
        let startDate = Calendar.app.date(byAdding: .day, value: -1, to: today)
        // 종료 날짜를 정해 목표 기간 길이를 확정합니다.
        // 이 값이 없으면 하루 목표 계산 자체를 할 수 없습니다.
        let endDate = Calendar.app.date(byAdding: .day, value: 14, to: today)

        model.setSelectedBook(sampleBookSearchItem)
        model.setPageRange(start: 1, end: 320)
        model.setReadingPeriod(startDate: startDate, endDate: endDate)
        model.setNonReadingDays([])
        return model
    }

    // 검색 결과 목록과 선택된 책을 직접 넣어 프리뷰 상태를 만듭니다.
    // 이 함수로 빈 결과/선택 완료 같은 분기 화면을 바로 재현합니다.
    static func makeBookSearchViewModel(
        books: [BookSearchItem],
        selectedBook: BookSearchItem? = nil
    ) -> BookSearchViewModel {
        let useCase = BookSearchUseCase(
            bookSearchProvider: PreviewBookSearchProvider(books: books)
        )
        let viewModel = BookSearchViewModel(bookSearchUseCase: useCase)
        viewModel.books = books
        viewModel.selectedBook = selectedBook
        return viewModel
    }

    // 검색 결과 목록과 선택된 책을 직접 넣어 프리뷰 상태를 만듭니다.
    // 이 함수로 빈 결과/선택 완료 같은 분기 화면을 바로 재현합니다.
    static func makeBookSearchViewModel() -> BookSearchViewModel {
        makeBookSearchViewModel(books: sampleSearchBooks)
    }
}

struct PreviewBookSearchProvider: BookSearchProviding {
    let books: [BookSearchItem]
    let totalPages: Int

    // 필요한 값을 밖에서 받아 시작할 수 있게 만든 생성자입니다.
    // 이렇게 해야 프리뷰/테스트에서 원하는 상황을 정확히 다시 만들 수 있습니다.
    init(books: [BookSearchItem], totalPages: Int = 320) {
        self.books = books
        self.totalPages = totalPages
    }

    // 실제 네트워크 대신 미리 준비한 목록을 바로 돌려줍니다.
    // 응답 대기 없이 검색 UI 전환을 빠르게 확인할 수 있습니다.
    func fetchBooks(query: String) async throws -> [BookSearchItem] {
        books
    }

    // 총 페이지 조회는 고정된 성공값만 돌려줍니다.
    // 계산보다 화면 단계 이동이 맞는지 검증에 집중하려는 의도입니다.
    func fetchBookTotalPages(isbn: String) async throws -> Int {
        totalPages
    }
}
#endif
