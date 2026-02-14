//
//  MainPreviewSupport.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
// 화면 값은 메인 스레드에서만 바꿔야 안전합니다.
// 이 표시를 붙여, 다른 스레드가 끼어들어 상태가 꼬이는 일을 막습니다.
@MainActor
extension PreviewSupport {
    // 홈 화면에 들어갈 읽는 책/완독 책 목록을 직접 넣어주는 헬퍼입니다.
    // 조합을 바꿔가며 빈 상태/일반 상태 분기를 빠르게 확인합니다.
    static func makeMainHomeViewModel(
        readingBooks: [FGUserBook],
        completedBooks: [FGUserBook]
    ) -> MainHomeViewModel {
        let service = PreviewBookManagementService(
            readingBooks: readingBooks,
            completedBooks: completedBooks
        )

        return MainHomeViewModel(
            readingLibraryUseCase: PreviewReadingLibraryUseCaseAdapter(service: service),
            notificationManager: PreviewNotificationManager()
        )
    }

    // 홈 화면에 들어갈 읽는 책/완독 책 목록을 직접 넣어주는 헬퍼입니다.
    // 조합을 바꿔가며 빈 상태/일반 상태 분기를 빠르게 확인합니다.
    static func makeMainHomeViewModel() -> MainHomeViewModel {
        makeMainHomeViewModel(
            readingBooks: [sampleReadingBook],
            completedBooks: [sampleCompletedBook]
        )
    }
}
#endif
