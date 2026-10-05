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

    @Test("권한 조회 중 앱 알림을 끄면 이전 조회 결과로 알림을 재등록하지 않는다")
    func updateMorningNotification_whenAppDisabledDuringAuthorization_doesNotAddRequest() async {
        let notificationCenter = UserNotificationCenterStub()
        let authorizationGate = AsyncGate()
        notificationCenter.requestAuthorizationGate = authorizationGate
        let settingsStore = MutableNotificationSettingsStoreStub(
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

        let updateTask = Task {
            await manager.updateMorningNotification(for: makeReadingBook(today: today))
        }
        #expect(await waitUntil { notificationCenter.requestAuthorizationCallCount == 1 })

        settingsStore.disabled = true
        await manager.clearRequests()
        await authorizationGate.open()
        await updateTask.value

        #expect(notificationCenter.removeAllPendingNotificationRequestsCallCount == 1)
        #expect(notificationCenter.addedIdentifiers.isEmpty)
    }

    @Test(
        "authorizationStatus(C6)는 iOS 권한 상태를 앱의 3가지 상태로 바꾼다",
        arguments: [
            (UNAuthorizationStatus.notDetermined, NotificationAuthorizationStatus.notDetermined),
            (.denied, .denied),
            (.authorized, .authorized),
            (.provisional, .authorized),
            (.ephemeral, .authorized)
        ]
    )
    func authorizationStatus_mapsSystemStatus(
        systemStatus: UNAuthorizationStatus,
        expected: NotificationAuthorizationStatus
    ) async {
        let notificationCenter = UserNotificationCenterStub()
        notificationCenter.authorizationStatus = systemStatus
        let manager = makeManager(notificationCenter: notificationCenter)

        let status = await manager.authorizationStatus()

        #expect(status == expected)
    }

    @Test("authorizationStatus(C6)는 알 수 없는 iOS 상태를 거절로 본다")
    func authorizationStatus_unknownSystemStatus_isDenied() async throws {
        let unknownStatus = try #require(UNAuthorizationStatus(rawValue: 99))
        let notificationCenter = UserNotificationCenterStub()
        notificationCenter.authorizationStatus = unknownStatus
        let manager = makeManager(notificationCenter: notificationCenter)

        let status = await manager.authorizationStatus()

        #expect(status == .denied)
    }

    @Test("authorizationStatus는 권한 팝업을 띄우지 않고 상태만 읽는다")
    func authorizationStatus_readsStatusWithoutRequestingAuthorization() async {
        let notificationCenter = UserNotificationCenterStub()
        notificationCenter.authorizationStatus = .notDetermined
        let manager = makeManager(notificationCenter: notificationCenter)

        let status = await manager.authorizationStatus()

        #expect(status == .notDetermined)
        #expect(notificationCenter.requestAuthorizationCallCount == 0)
    }

    private func makeManager(notificationCenter: UserNotificationCenterStub) -> NotificationManager {
        NotificationManager(
            notificationCenter: notificationCenter,
            todayProvider: FixedReadingDateProvider(todayValue: makeDate("2025-01-01")),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 8, reminderMinute: 0)
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
    var requestAuthorizationGate: AsyncGate?

    var requestAuthorizationCallCount = 0
    var addedIdentifiers: [String] = []
    var removedIdentifiers: [String] = []
    var removeAllPendingNotificationRequestsCallCount = 0

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCallCount += 1
        if let requestAuthorizationGate {
            await requestAuthorizationGate.wait()
        }
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

private final class MutableNotificationSettingsStoreStub: NotificationSettingsStoring {
    var disabled: Bool
    private let reminderHour: Int
    private let reminderMinute: Int

    init(disabled: Bool, reminderHour: Int, reminderMinute: Int) {
        self.disabled = disabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        disabled = isNotificationDisabled
    }

    func fetchNotificationDisabled() -> Bool {
        disabled
    }

    func saveNotificationTime(hour: Int, minute: Int) {}

    func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        (reminderHour, reminderMinute)
    }
}
