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
        MainHomeViewModel(
            bookManagementService: PreviewBookManagementService(
                readingBooks: readingBooks,
                completedBooks: completedBooks
            ),
            notificationManager: PreviewNotificationManager()
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
