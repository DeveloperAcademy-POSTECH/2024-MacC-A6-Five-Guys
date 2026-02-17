//
//  MainPreviewSupport.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
@MainActor
extension PreviewSupport {
    static func makeMainHomeViewModel(
        readingBooks: [FGUserBook],
        completedBooks: [FGUserBook]
    ) -> MainHomeViewModel {
        let previewUseCase = PreviewBookUseCaseStub(
            readingBooks: readingBooks,
            completedBooks: completedBooks
        )

        return MainHomeViewModel(
            readingLibraryUseCase: previewUseCase,
            homeNotificationUseCase: previewUseCase
        )
    }

    static func makeMainHomeViewModel() -> MainHomeViewModel {
        makeMainHomeViewModel(
            readingBooks: [sampleReadingBook],
            completedBooks: [sampleCompletedBook]
        )
    }
}
#endif
