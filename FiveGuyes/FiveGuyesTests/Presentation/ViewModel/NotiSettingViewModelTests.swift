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
    @Test("NotiSettingViewModel: 저장된 설정 로드는 저장과 알림 요청을 발생시키지 않는다")
    func notiSetting_loadPersistedSettings_doesNotPersistOrRequestNotification() {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 8,
            reminderMinute: 30
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore,
            nowProvider: { makeDate("2025-01-01") }
        )

        viewModel.loadPersistedSettings()

        #expect(viewModel.isNotificationDisabled)
        let timeComponents = Calendar.app.dateComponents([.hour, .minute], from: viewModel.selectedTime)
        #expect(timeComponents.hour == 8)
        #expect(timeComponents.minute == 30)
        #expect(settingsStore.savedNotificationDisabled == nil)
        #expect(settingsStore.savedReminderHour == nil)
        #expect(settingsStore.savedReminderMinute == nil)
        #expect(notificationService.clearRequestsCallCount == 0)
        #expect(notificationService.setupAllNotificationsCallCount == 0)
        #expect(notificationService.updateMorningNotificationCallCount == 0)
        #expect(notificationService.requestAuthorizationCallCount == 0)
    }

    @Test("NotiSettingViewModel: 알림 비활성화 시 요청 삭제 호출")
    func notiSetting_disable_clearsRequests() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        viewModel.loadPersistedSettings()
        viewModel.setNotificationDisabled(true, userBook: makeBook())

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

    @Test("NotiSettingViewModel: C5 알림 끄기 스위치를 켜면 끔, 끄면 받음으로 저장된다")
    func notiSetting_c5_toggleMapsToDisabledSetting() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 9,
            reminderMinute: 0
        )
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: settingsStore
        )

        viewModel.setNotificationDisabled(true, userBook: makeBook())
        #expect(await waitUntil { settingsStore.savedNotificationDisabled == true })
        #expect(viewModel.isNotificationDisabled)

        viewModel.setNotificationDisabled(false, userBook: makeBook())
        #expect(await waitUntil { settingsStore.savedNotificationDisabled == false })
        #expect(viewModel.isNotificationDisabled == false)
    }

    @Test("NotiSettingViewModel: C9 읽는 책이 없어도 알림을 끄면 대기 중인 알림을 모두 제거한다")
    func notiSetting_c9_disableWithoutBook_clearsRequests() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 9,
            reminderMinute: 0
        )
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: settingsStore
        )

        viewModel.setNotificationDisabled(true, userBook: nil)

        #expect(await waitUntil { notificationService.clearRequestsCallCount == 1 })
        #expect(settingsStore.savedNotificationDisabled == true)
        #expect(notificationService.setupAllNotificationsCallCount == 0)
        #expect(notificationService.requestAuthorizationCallCount == 0)
    }

    @Test("NotiSettingViewModel: C8 읽는 책이 없을 때 알림을 받음으로 바꾸면 설정만 저장한다")
    func notiSetting_c8_enableWithoutBook_onlySavesSetting() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: settingsStore
        )

        viewModel.setNotificationDisabled(false, userBook: nil)

        #expect(await waitUntil { settingsStore.savedNotificationDisabled == false })
        #expect(notificationService.clearRequestsCallCount == 0)
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
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore,
            nowProvider: { makeDate("2025-01-01") }
        )

        let baseDate = makeDate("2025-01-01")
        let selectedTime = Calendar.app.date(
            bySettingHour: 21,
            minute: 15,
            second: 0,
            of: baseDate
        ) ?? baseDate
        viewModel.loadPersistedSettings()
        viewModel.updateReminderTime(selectedTime, userBook: makeBook())

        #expect(
            await waitUntil {
                settingsStore.savedReminderHour == 21 &&
                    settingsStore.savedReminderMinute == 15 &&
                    notificationService.updateMorningNotificationCallCount == 1
            }
        )

        #expect(settingsStore.savedReminderHour == 21)
        #expect(settingsStore.savedReminderMinute == 15)
        #expect(notificationService.updateMorningNotificationCallCount == 1)
    }

    @Test("NotiSettingViewModel: 알림 비활성화 상태에서는 시간 변경 시 알림을 재등록하지 않음")
    func notiSetting_timeChange_whenDisabled_doesNotUpdateNotification() async {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 7,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore,
            nowProvider: { makeDate("2025-01-01") }
        )

        let baseDate = makeDate("2025-01-01")
        viewModel.isNotificationDisabled = true
        viewModel.selectedTime = Calendar.app.date(
            bySettingHour: 10,
            minute: 40,
            second: 0,
            of: baseDate
        ) ?? baseDate

        viewModel.handleNotificationTimeChange(userBook: makeBook())

        #expect(
            await waitUntil {
                settingsStore.savedReminderHour == 10 &&
                    settingsStore.savedReminderMinute == 40
            }
        )
        #expect(settingsStore.savedReminderHour == 10)
        #expect(settingsStore.savedReminderMinute == 40)
        #expect(notificationService.updateMorningNotificationCallCount == 0)
    }

    @Test("NotiSettingViewModel: 빠른 연속 시간 변경 시 마지막 요청만 처리")
    func notiSetting_timeChange_cancelsPreviousTask() async {
        let notificationService = NotificationManagerStub()
        notificationService.updateMorningNotificationDelayNanoseconds = 80_000_000
        notificationService.ignoreCancelledCalls = true

        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 7,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
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
                notificationService.updateMorningNotificationCallCount == 1
            }
        )

        #expect(settingsStore.savedReminderHour == 9)
        #expect(settingsStore.savedReminderMinute == 20)
        #expect(notificationService.updateMorningNotificationCallCount == 1)
    }

    @Test("NotiSettingViewModel: 시스템 설정 이동 요청 위임")
    func notiSetting_openSystemSettings_delegatesToService() {
        let notificationService = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 7,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        viewModel.openSystemSettings()

        #expect(settingsOpener.openSettingsCallCount == 1)
    }
}
