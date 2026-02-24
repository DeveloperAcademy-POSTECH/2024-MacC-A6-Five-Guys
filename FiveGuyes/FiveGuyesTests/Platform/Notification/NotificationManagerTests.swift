//
//  NotificationManagerTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2026-02-17.
//

@testable import FiveGuyes
import Foundation
import Testing
import UserNotifications

@Suite("NotificationManager 테스트")
struct NotificationManagerTests {
    @Test("updateMorningNotification은 canSendNotifications가 false면 재등록하지 않는다")
    func updateMorningNotification_whenCannotSend_doesNotAddRequest() async {
        let notificationCenter = UNUserNotificationCenter.current()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 8,
            reminderMinute: 0
        )
        let today = makeDate("2025-01-01")
        let manager = NotificationManager(
            notificationCenter: notificationCenter,
            todayProvider: FixedReadingDateProvider(todayValue: today),
            settingsStore: settingsStore
        )
        let readingBook = makeReadingBook(today: today)
        let identifier = "\(readingBook.id)-morning"

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        let beforeCount = await pendingRequestCount(
            in: notificationCenter,
            identifier: identifier
        )

        await manager.updateMorningNotification(for: readingBook)

        let afterCount = await pendingRequestCount(
            in: notificationCenter,
            identifier: identifier
        )

        #expect(beforeCount == 0)
        #expect(afterCount == 0)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
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

    private func makeReadingBook(today: Date) -> FGUserBook {
        let nextReadingDate = today.addDays(1)
        return FGUserBook(
            id: UUID(),
            bookMetaData: FGBookMetaData(
                title: "테스트 도서",
                author: "테스트 저자",
                coverImageURL: nil,
                totalPages: 300
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: 300,
                startDate: today,
                targetEndDate: today.addDays(10),
                excludedReadingDays: []
            ),
            readingProgress: FGReadingProgress(
                dailyReadingRecords: [
                    nextReadingDate.toYearMonthDayString(): ReadingRecord(targetPages: 15, pagesRead: 0)
                ],
                lastReadDate: today,
                lastReadPage: 15
            ),
            completionStatus: FGCompletionStatus(
                isCompleted: false,
                reviewAfterCompletion: ""
            )
        )
    }

    private func pendingRequestCount(
        in center: UNUserNotificationCenter,
        identifier: String
    ) async -> Int {
        let requests = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
        return requests.filter { $0.identifier == identifier }.count
    }
}

private struct FixedReadingDateProvider: ReadingDateProviding {
    let todayValue: Date

    func today() -> Date {
        todayValue
    }
}
