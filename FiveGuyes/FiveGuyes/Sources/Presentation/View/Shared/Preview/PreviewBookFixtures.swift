//
//  PreviewBookFixtures.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
import Foundation

@MainActor
extension PreviewSupport {
    static var sampleReadingBook: FGUserBook {
        makeBook(title: "읽는 중인 샘플 도서", isCompleted: false)
    }

    static var sampleCompletedBook: FGUserBook {
        makeBook(title: "완독한 샘플 도서", isCompleted: true)
    }

    static var sampleBooksForCarousel: [FGUserBook] {
        [
            makeBook(title: "샘플 도서 1", isCompleted: false),
            makeBook(title: "샘플 도서 2", isCompleted: false),
            makeBook(title: "샘플 도서 3", isCompleted: false)
        ]
    }

    static func makeBook(
        title: String,
        isCompleted: Bool,
        coverImageURL: String? = nil,
        targetEndDateOffset: Int = 10,
        lastReadPage: Int? = nil,
        reviewAfterCompletion: String? = nil
    ) -> FGUserBook {
        let today = Date().adjustedDate()
        let recordKey = today.toYearMonthDayString()
        let readingRecords = [recordKey: ReadingRecord(targetPages: 20, pagesRead: isCompleted ? 20 : 12)]
        let targetEndDate = Calendar.app.date(byAdding: .day, value: targetEndDateOffset, to: today) ?? today
        let resolvedLastReadPage = lastReadPage ?? (isCompleted ? 320 : 120)
        let resolvedReview = reviewAfterCompletion ?? (isCompleted ? "프리뷰용 완독 소감입니다." : "")

        return FGUserBook(
            id: UUID(),
            bookMetaData: FGBookMetaData(
                title: title,
                author: "샘플 저자",
                coverImageURL: coverImageURL,
                totalPages: 320
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: 320,
                startDate: today,
                targetEndDate: targetEndDate,
                excludedReadingDays: []
            ),
            readingProgress: FGReadingProgress(
                dailyReadingRecords: readingRecords,
                lastReadDate: today,
                lastReadPage: resolvedLastReadPage
            ),
            completionStatus: FGCompletionStatus(
                isCompleted: isCompleted,
                reviewAfterCompletion: resolvedReview
            )
        )
    }
}
#endif
