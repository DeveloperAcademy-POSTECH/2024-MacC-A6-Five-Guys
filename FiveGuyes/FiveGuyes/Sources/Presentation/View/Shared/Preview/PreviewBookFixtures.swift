//
//  PreviewBookFixtures.swift
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

    // 화면 분기를 확인할 때 쓸 샘플 책을 빠르게 만드는 함수입니다.
    // 완독/미완독 상태를 쉽게 바꿔 다양한 화면을 검증합니다.
    static func makeBook(
        title: String,
        isCompleted: Bool,
        coverImageURL: String? = nil,
        targetEndDateOffset: Int = 10,
        lastReadPage: Int? = nil,
        reviewAfterCompletion: String? = nil
    ) -> FGUserBook {
        // 계산 기준이 흔들리지 않게 오늘 날짜를 먼저 고정합니다.
        // 기준이 매번 바뀌면 같은 프리뷰가 다르게 보여 디버깅이 어려워집니다.
        let today = DefaultReadingDateProvider().today()
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
