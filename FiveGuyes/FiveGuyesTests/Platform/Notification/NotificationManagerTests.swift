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
    @Test("updateMorningNotification은 앱 설정이 켜져 있으면 알림을 등록한다")
    func updateMorningNotification_whenAppEnabled_addsRequest() async {
        let notificationCenter = UserNotificationCenterStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
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

        await manager.updateMorningNotification(for: readingBook)

        #expect(notificationCenter.requestAuthorizationCallCount == 1)
        #expect(notificationCenter.addedIdentifiers == [identifier])
    }

    @Test("updateMorningNotification은 앱 설정이 꺼져 있으면 등록하지도, 권한을 요청하지도 않는다")
    func updateMorningNotification_whenAppDisabled_doesNotAddRequestOrRequestAuthorization() async {
        let notificationCenter = UserNotificationCenterStub()
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

        await manager.updateMorningNotification(for: readingBook)

        #expect(notificationCenter.requestAuthorizationCallCount == 0)
        #expect(notificationCenter.addedIdentifiers.isEmpty)
    }

    @Test("updateMorningNotification은 앱 설정이 켜져 있어도 OS 권한이 거부되면 등록하지 않는다")
    func updateMorningNotification_whenAppEnabledButSystemDenied_doesNotAddRequest() async {
        let notificationCenter = UserNotificationCenterStub()
        notificationCenter.authorizationStatus = .denied
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
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

        await manager.updateMorningNotification(for: readingBook)

        // 앱 설정이 켜져 있으므로 권한 요청까지는 진행하되, OS가 거부한 상태에서는 등록하지 않는다.
        #expect(notificationCenter.requestAuthorizationCallCount == 1)
        #expect(notificationCenter.addedIdentifiers.isEmpty)
    }

    @Test("isSystemAuthorized는 권한 팝업을 띄우지 않고 상태만 읽는다")
    func isSystemAuthorized_readsStatusWithoutRequestingAuthorization() async {
        let notificationCenter = UserNotificationCenterStub()
        notificationCenter.authorizationStatus = .notDetermined
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 8,
            reminderMinute: 0
        )
        let manager = NotificationManager(
            notificationCenter: notificationCenter,
            todayProvider: FixedReadingDateProvider(todayValue: makeDate("2025-01-01")),
            settingsStore: settingsStore
        )

        let isAuthorized = await manager.isSystemAuthorized()

        #expect(isAuthorized == false)
        #expect(notificationCenter.requestAuthorizationCallCount == 0)
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
}

private struct FixedReadingDateProvider: ReadingDateProviding {
    let todayValue: Date

    func today() -> Date {
        todayValue
    }
}

private final class UserNotificationCenterStub: UserNotificationCentering {
    var authorizationStatus: UNAuthorizationStatus = .authorized

    var requestAuthorizationCallCount = 0
    var addedIdentifiers: [String] = []
    var removedIdentifiers: [String] = []
    var removeAllPendingNotificationRequestsCallCount = 0

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCallCount += 1
        return authorizationStatus == .authorized
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatus
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedIdentifiers.append(request.identifier)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }

    func removeAllPendingNotificationRequests() {
        removeAllPendingNotificationRequestsCallCount += 1
    }
}
