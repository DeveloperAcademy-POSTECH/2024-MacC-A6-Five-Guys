//
//  FGUserBook+PreviewDummy.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/19/25.
//

import Foundation

// FGUserBook+PreviewDummy.swift
#if DEBUG
extension FGUserBook {
    static var dummy: FGUserBook {
        FGUserBook(
            id: UUID(),
            bookMetaData: FGBookMetaData(
                title: "Sample Book Title",
                author: "Sample Author",
                coverImageURL: "https://picsum.photos/200/300",
                totalPages: 300
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: 300,
                startDate: Date(),
                targetEndDate: Date().addingTimeInterval(86400 * 30),
                excludedReadingDays: []
            ),
            readingProgress: FGReadingProgress(
                dailyReadingRecords: [:],
                lastReadDate: nil,
                lastReadPage: 0
            ),
            completionStatus: FGCompletionStatus(
                isCompleted: false,
                reviewAfterCompletion: ""
            )
        )
    }
}
#endif
