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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
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
        let viewModel = makeViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        viewModel.openSystemSettings()

        #expect(settingsOpener.openSettingsCallCount == 1)
    }

    @Test("NotiSettingViewModel: 설정 화면 진입은 권한 팝업을 띄우지 않고 상태만 조회한다")
    func notiSetting_refreshAuthorization_doesNotRequestAuthorization() async {
        let notificationService = NotificationManagerStub()
        notificationService.isAuthorized = false
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        await viewModel.refreshSystemNotificationAuthorization()

        // 화면 진입은 상태 표시용 조회이므로 OS 권한 팝업을 띄워서는 안 된다.
        #expect(notificationService.requestAuthorizationCallCount == 0)
        #expect(notificationService.isSystemAuthorizedCallCount == 1)
        #expect(viewModel.isSystemNotificationEnabled == false)
    }

    @Test("NotiSettingViewModel: 앱 알림을 켜서 권한을 허용하면 배너가 사라진다")
    func notiSetting_enable_afterAuthorizationGranted_refreshesBanner() async {
        let notificationService = NotificationManagerStub()
        notificationService.isAuthorized = false
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 화면 진입: OS 권한이 아직 허용되지 않아 배너가 보인다.
        await viewModel.refreshSystemNotificationAuthorization()
        #expect(viewModel.isSystemNotificationEnabled == false)

        // 앱 알림을 켜면 권한 팝업이 뜨고, 사용자가 허용한 상황을 가정한다.
        notificationService.isAuthorized = true
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())

        #expect(await waitUntil { viewModel.isSystemNotificationEnabled })

        // 허용한 뒤에는 배너가 남아 있어서는 안 된다.
        #expect(viewModel.isSystemNotificationEnabled)
        #expect(notificationService.setupAllNotificationsCallCount == 1)
    }

    @Test("NotiSettingViewModel: 뒤늦게 끝난 이전 권한 조회가 최신 배너 상태를 덮어쓰지 않는다")
    func notiSetting_staleAuthorizationResult_doesNotOverwriteLatestState() async {
        let notificationService = NotificationManagerStub()
        notificationService.isAuthorized = true
        notificationService.isSystemAuthorizedDelayNanoseconds = 300_000_000
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 앱 알림을 켠다. 이 조회는 느리고, 허용(true)을 반환할 예정이다.
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())
        #expect(await waitUntil { notificationService.isSystemAuthorizedCallCount == 1 })

        // 조회가 끝나기 전에 다시 끈다. 이쪽 조회는 즉시 거부(false)를 반환한다.
        notificationService.isAuthorized = false
        notificationService.isSystemAuthorizedDelayNanoseconds = 0
        viewModel.isNotificationDisabled = true
        viewModel.handleNotificationStatusChange(userBook: makeBook())

        #expect(await waitUntil { viewModel.isSystemNotificationEnabled == false })

        // 앞선 느린 조회가 뒤늦게 끝나도 최신 상태(false)를 되돌려서는 안 된다.
        let becameStale = await waitUntil(timeoutNanoseconds: 500_000_000) {
            viewModel.isSystemNotificationEnabled
        }
        #expect(becameStale == false)
    }

    @Test("NotiSettingViewModel: 화면 진입 조회가 토글 경로의 최신 배너 상태를 덮어쓰지 않는다")
    func notiSetting_initialAuthorizationResult_doesNotOverwriteToggleState() async {
        let notificationService = NotificationManagerStub()
        let initialAuthorizationGate = AsyncGate()
        notificationService.isSystemAuthorizedResults = [false, true]
        notificationService.isSystemAuthorizedGates = [initialAuthorizationGate]
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 화면 진입 조회는 거부(false)를 반환하기 전에 대기한다.
        let initialRefreshTask = Task {
            await viewModel.refreshSystemNotificationAuthorization()
        }
        #expect(await waitUntil { notificationService.isSystemAuthorizedCallCount == 1 })

        // 그 사이 토글 경로가 허용(true)을 반영한다.
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())
        #expect(
            await waitUntil {
                notificationService.isSystemAuthorizedCallCount == 2 &&
                    viewModel.isSystemNotificationEnabled
            }
        )

        // 대기 중이던 진입 조회도 반드시 재개해 끝낸다.
        await initialAuthorizationGate.open()
        await initialRefreshTask.value

        #expect(viewModel.isSystemNotificationEnabled)
    }

    @Test("NotiSettingViewModel: 권한 팝업 중 화면 복귀 조회 뒤에도 토글의 최신 권한 상태를 반영한다")
    func notiSetting_toggleAuthorizationResult_overwritesRefreshDuringPermissionPrompt() async {
        let notificationService = NotificationManagerStub()
        let permissionPromptGate = AsyncGate()
        notificationService.isSystemAuthorizedResults = [false, true]
        notificationService.setupAllNotificationsGate = permissionPromptGate
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 알림을 켜면 OS 권한 팝업이 열린 상태로 대기한다.
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())
        #expect(await waitUntil { notificationService.setupAllNotificationsCallCount == 1 })

        // 팝업이 열린 사이 화면이 복귀하면서 거부(false) 상태를 조회한다.
        await viewModel.refreshSystemNotificationAuthorization()
        #expect(viewModel.isSystemNotificationEnabled == false)

        // 사용자가 권한을 허용해 팝업을 닫으면 토글 경로의 최종 조회는 허용(true)이다.
        await permissionPromptGate.open()
        #expect(await waitUntil { notificationService.isSystemAuthorizedCallCount == 2 })
        await Task.yield()

        #expect(viewModel.isSystemNotificationEnabled)
    }

    private func makeViewModel(
        notificationService: NotificationManagerStub,
        settingsOpener: SystemSettingsOpenerStub,
        settingsStore: NotificationSettingsStoreStub,
        nowProvider: @escaping () -> Date = Date.init
    ) -> NotiSettingViewModel {
        let useCase = NotificationSettingUseCase(
            notificationService: notificationService,
            systemSettingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        return NotiSettingViewModel(
            notificationSettingUseCase: useCase,
            nowProvider: nowProvider
        )
    }
}
