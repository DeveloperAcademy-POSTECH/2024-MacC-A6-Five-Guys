//
//  NotiSettingViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("NotiSettingViewModel 테스트")
@MainActor
struct NotiSettingViewModelTests {
    @Test("NotiSettingViewModel: 저장된 설정 로드")
    func notiSetting_loadPersistedSettings() {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 8,
            reminderMinute: 30
        )
        let viewModel = NotiSettingViewModel(
            notificationService: notificationService,
            settingsStore: settingsStore,
            nowProvider: { makeDate("2025-01-01") }
        )

        viewModel.loadPersistedSettings()

        #expect(viewModel.isNotificationDisabled)
        let timeComponents = Calendar.app.dateComponents([.hour, .minute], from: viewModel.selectedTime)
        #expect(timeComponents.hour == 8)
        #expect(timeComponents.minute == 30)
    }

    @Test("NotiSettingViewModel: 알림 비활성화 시 요청 삭제 호출")
    func notiSetting_disable_clearsRequests() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 9,
            reminderMinute: 0
        )
        let viewModel = NotiSettingViewModel(
            notificationService: notificationService,
            settingsStore: settingsStore
        )

        viewModel.isNotificationDisabled = true
        viewModel.handleNotificationStatusChange(userBook: makeBook())

        #expect(
            await waitUntil {
                settingsStore.savedNotificationDisabled == true &&
                    notificationService.clearRequestsCallCount == 1
            }
        )

        #expect(settingsStore.savedNotificationDisabled == true)
        #expect(notificationService.clearRequestsCallCount == 1)
        #expect(notificationService.setupAllNotificationsCallCount == 0)
    }

    @Test("NotiSettingViewModel: 시간 변경 시 설정 저장 및 알림 업데이트")
    func notiSetting_timeChange_updatesSettingsAndNotification() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 7,
            reminderMinute: 0
        )
        let viewModel = NotiSettingViewModel(
            notificationService: notificationService,
            settingsStore: settingsStore,
            nowProvider: { makeDate("2025-01-01") }
        )

        let baseDate = makeDate("2025-01-01")
        viewModel.selectedTime = Calendar.app.date(
            bySettingHour: 21,
            minute: 15,
            second: 0,
            of: baseDate
        ) ?? baseDate
        viewModel.handleNotificationTimeChange(userBook: makeBook())

        #expect(
            await waitUntil {
                settingsStore.savedReminderHour == 21 &&
                    settingsStore.savedReminderMinute == 15 &&
                    notificationService.updateNotificationCallCount == 1
            }
        )

        #expect(settingsStore.savedReminderHour == 21)
        #expect(settingsStore.savedReminderMinute == 15)
        #expect(notificationService.updateNotificationCallCount == 1)
    }

    @Test("NotiSettingViewModel: 빠른 연속 시간 변경 시 마지막 요청만 처리")
    func notiSetting_timeChange_cancelsPreviousTask() async {
        let notificationService = NotificationManagerStub()
        notificationService.updateNotificationDelayNanoseconds = 80_000_000
        notificationService.ignoreCancelledCalls = true

        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 7,
            reminderMinute: 0
        )
        let viewModel = NotiSettingViewModel(
            notificationService: notificationService,
            settingsStore: settingsStore,
            nowProvider: { makeDate("2025-01-01") }
        )

        let baseDate = makeDate("2025-01-01")
        let firstTime = Calendar.app.date(bySettingHour: 8, minute: 10, second: 0, of: baseDate) ?? baseDate
        let secondTime = Calendar.app.date(bySettingHour: 9, minute: 20, second: 0, of: baseDate) ?? baseDate

        viewModel.selectedTime = firstTime
        viewModel.handleNotificationTimeChange(userBook: makeBook())
        viewModel.selectedTime = secondTime
        viewModel.handleNotificationTimeChange(userBook: makeBook())

        #expect(
            await waitUntil(timeoutNanoseconds: 1_000_000_000) {
                notificationService.updateNotificationCallCount == 1
            }
        )

        #expect(settingsStore.savedReminderHour == 9)
        #expect(settingsStore.savedReminderMinute == 20)
        #expect(notificationService.updateNotificationCallCount == 1)
    }
}
