//
//  FGReadingProgressNotificationTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2026-02-14.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("FGReadingProgress 알림 계산 테스트")
struct FGReadingProgressNotificationTests {
    @Test("findNextReadingDay는 today 이전 날짜를 건너뛴다")
    func findNextReadingDay_skipsPastDates() {
        let progress = FGReadingProgress(
            dailyReadingRecords: [
                "2025-01-01": ReadingRecord(targetPages: 20, pagesRead: 0),
                "2025-01-03": ReadingRecord(targetPages: 40, pagesRead: 0)
            ],
            lastReadDate: nil,
            lastReadPage: 0
        )

        let nextDay = progress.findNextReadingDay(today: makeDate("2025-01-02"))

        #expect(nextDay == makeDate("2025-01-03"))
    }

    @Test("findNextReadingPagesPerDay는 legacy(lastReadPage=다음 페이지) 케이스에서 페이지를 건너뛰지 않는다")
    func findNextReadingPagesPerDay_legacyNextPageSemantics() {
        let settings = makeSettings(targetEndPage: 200, targetEndDate: makeDate("2025-01-10"))
        let progress = FGReadingProgress(
            dailyReadingRecords: [
                "2025-01-05": ReadingRecord(targetPages: 150, pagesRead: 150)
            ],
            lastReadDate: makeDate("2025-01-05"),
            lastReadPage: 151
        )

        let pages = progress.findNextReadingPagesPerDay(
            for: settings,
            today: makeDate("2025-01-06")
        )

        #expect(pages == 10)
    }

    @Test("findNextReadingPagesPerDay는 mixed 데이터에서 records 기반 최대 페이지를 우선 사용한다")
    func findNextReadingPagesPerDay_prefersRecordsOverStaleLastReadPage() {
        let settings = makeSettings(targetEndPage: 300, targetEndDate: makeDate("2025-01-10"))
        let progress = FGReadingProgress(
            dailyReadingRecords: [
                "2025-01-01": ReadingRecord(targetPages: 120, pagesRead: 120),
                "2025-01-02": ReadingRecord(targetPages: 140, pagesRead: 140)
            ],
            lastReadDate: makeDate("2025-01-02"),
            lastReadPage: 80
        )

        let pages = progress.findNextReadingPagesPerDay(
            for: settings,
            today: makeDate("2025-01-03")
        )

        #expect(pages == 20)
    }

    @Test("findNextReadingPagesPerDay는 record가 없으면 lastReadPage + 1로 fallback 한다")
    func findNextReadingPagesPerDay_fallbacksWithoutRecords() {
        let settings = makeSettings(targetEndPage: 300, targetEndDate: makeDate("2025-01-10"))
        let progress = FGReadingProgress(
            dailyReadingRecords: [:],
            lastReadDate: nil,
            lastReadPage: 50
        )

        let pages = progress.findNextReadingPagesPerDay(
            for: settings,
            today: makeDate("2025-01-03")
        )

        #expect(pages == 31)
    }

    @Test("findNextReadingPagesPerDay는 stale record가 target을 넘어도 범위를 클램프한다")
    func findNextReadingPagesPerDay_clampsOutOfRangeRecord() {
        let settings = makeSettings(targetEndPage: 300, targetEndDate: makeDate("2025-01-10"))
        let progress = FGReadingProgress(
            dailyReadingRecords: [
                "2025-01-02": ReadingRecord(targetPages: 300, pagesRead: 350)
            ],
            lastReadDate: makeDate("2025-01-02"),
            lastReadPage: 120
        )

        let pages = progress.findNextReadingPagesPerDay(
            for: settings,
            today: makeDate("2025-01-03")
        )

        #expect(pages == 0)
    }

    @Test("NotificationType.morning은 페이지 계산 결과를 제목에 반영하고 dateContent는 다음 독서일을 반환한다")
    func notificationType_usesTodayForTitleAndDate() {
        let settings = makeSettings(targetEndPage: 300, targetEndDate: makeDate("2025-01-10"))
        let progress = FGReadingProgress(
            dailyReadingRecords: [
                "2025-01-03": ReadingRecord(targetPages: 120, pagesRead: 120),
                "2025-01-04": ReadingRecord(targetPages: 140, pagesRead: 0)
            ],
            lastReadDate: makeDate("2025-01-03"),
            lastReadPage: 120
        )
        let book = FGUserBook(
            id: UUID(),
            bookMetaData: FGBookMetaData(
                title: "테스트",
                author: "저자",
                coverImageURL: nil,
                totalPages: 300
            ),
            userSettings: settings,
            readingProgress: progress,
            completionStatus: FGCompletionStatus(isCompleted: false, reviewAfterCompletion: "")
        )
        let notificationType = NotificationType.morning(readingBook: book)
        let today = makeDate("2025-01-03")

        let (title, _) = notificationType.descriptionContent(today: today)
        let scheduledDate = notificationType.dateContent(today: today)

        let expectedTitles: Set<String> = [
            "오늘 목표는 22쪽이에요!",
            "독서로 오늘 하루를 시작해 볼까요?",
            "22쪽으로 오늘을 시작해요!"
        ]

        #expect(expectedTitles.contains(title))
        #expect(scheduledDate == makeDate("2025-01-04"))
    }

    private func makeSettings(targetEndPage: Int, targetEndDate: Date) -> FGUserSetting {
        FGUserSetting(
            startPage: 1,
            targetEndPage: targetEndPage,
            startDate: makeDate("2025-01-01"),
            targetEndDate: targetEndDate,
            excludedReadingDays: []
        )
    }

    private func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }
}
