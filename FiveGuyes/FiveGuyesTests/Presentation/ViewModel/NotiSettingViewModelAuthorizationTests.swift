//
//  NotiSettingViewModelAuthorizationTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("NotiSettingViewModel 권한 테스트")
@MainActor
struct NotiSettingViewModelAuthorizationTests {
    @Test(
        "NotiSettingViewModel: C6 OS 알림 꺼짐 배너는 받음 + 거절일 때만 보인다",
        arguments: [
            (NotificationAuthorizationStatus.notDetermined, false, false),
            (.authorized, false, false),
            (.denied, false, true),
            (.notDetermined, true, false),
            (.authorized, true, false),
            (.denied, true, false)
        ]
    )
    func notiSetting_c6_bannerVisibility(
        status: NotificationAuthorizationStatus,
        isNotificationDisabled: Bool,
        expectedVisible: Bool
    ) {
        let viewModel = makeNotiSettingViewModel(
            notificationService: NotificationManagerStub(),
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 9, reminderMinute: 0)
        )

        viewModel.systemAuthorizationStatus = status
        viewModel.isNotificationDisabled = isNotificationDisabled

        #expect(viewModel.isSystemNotificationBannerVisible == expectedVisible)
    }

    @Test("NotiSettingViewModel: C6 복귀 시 권한 조회 결과가 미결정이면 배너를 보이지 않는다")
    func notiSetting_c6_returnWithNotDetermined_hidesBanner() async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = .notDetermined
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 9, reminderMinute: 0)
        )

        await viewModel.handleReturnToForeground(userBook: nil)

        #expect(viewModel.systemAuthorizationStatus == .notDetermined)
        #expect(viewModel.isSystemNotificationBannerVisible == false)
    }

    @Test(
        "NotiSettingViewModel: C2 받음 + 미결정이면 책이 없어도 진입 시 팝업을 1회 띄우고 결과로 배너를 갱신한다",
        arguments: [
            (NotificationAuthorizationStatus.authorized, false),
            (.denied, true)
        ]
    )
    func notiSetting_c2_entryWithNotDetermined_requestsAuthorizationOnce(
        resultStatus: NotificationAuthorizationStatus,
        expectedBannerVisible: Bool
    ) async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = .notDetermined
        notificationService.statusAfterRequest = resultStatus
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 9, reminderMinute: 0)
        )

        await viewModel.handleScreenEntry()

        #expect(notificationService.requestAuthorizationCallCount == 1)
        #expect(viewModel.systemAuthorizationStatus == resultStatus)
        #expect(viewModel.isSystemNotificationBannerVisible == expectedBannerVisible)
        #expect(notificationService.setupAllNotificationsCallCount == 0)
        #expect(notificationService.clearRequestsCallCount == 0)
    }

    @Test(
        "NotiSettingViewModel: C3 진입 시 권한이 이미 결정됐으면 팝업 없이 상태만 조회한다",
        arguments: [
            (NotificationAuthorizationStatus.authorized, false),
            (.denied, true)
        ]
    )
    func notiSetting_c3_entryWithDecidedStatus_onlyReadsStatus(
        status: NotificationAuthorizationStatus,
        expectedBannerVisible: Bool
    ) async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = status
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 9, reminderMinute: 0)
        )

        await viewModel.handleScreenEntry()

        #expect(notificationService.requestAuthorizationCallCount == 0)
        #expect(viewModel.systemAuthorizationStatus == status)
        #expect(viewModel.isSystemNotificationBannerVisible == expectedBannerVisible)
    }

    @Test("NotiSettingViewModel: C2 끔 + 미결정이면 진입해도 팝업을 띄우지 않는다")
    func notiSetting_c2_entryWhenDisabled_doesNotRequestAuthorization() async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = .notDetermined
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: true, reminderHour: 9, reminderMinute: 0)
        )

        await viewModel.handleScreenEntry()

        #expect(notificationService.requestAuthorizationCallCount == 0)
        #expect(viewModel.systemAuthorizationStatus == .notDetermined)
        #expect(viewModel.isSystemNotificationBannerVisible == false)
    }

    @Test(
        "NotiSettingViewModel: C4 복귀 시 권한을 요청하지 않고 조회하며, 받음 + 허용 + 책이 있을 때만 다시 등록한다",
        arguments: [
            (NotificationAuthorizationStatus.authorized, false, true, 1),
            (.authorized, false, false, 0),
            (.authorized, true, true, 0),
            (.denied, false, true, 0),
            (.notDetermined, false, true, 0)
        ]
    )
    func notiSetting_c4_returnToForeground_reregistersOnlyWhenAllowed(
        status: NotificationAuthorizationStatus,
        isNotificationDisabled: Bool,
        hasBook: Bool,
        expectedSetupCount: Int
    ) async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = status
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(
                disabled: isNotificationDisabled,
                reminderHour: 9,
                reminderMinute: 0
            )
        )
        let book = makeBook()

        await viewModel.handleReturnToForeground(userBook: hasBook ? book : nil)

        #expect(notificationService.requestAuthorizationCallCount == 0)
        #expect(notificationService.setupAllNotificationsCallCount == expectedSetupCount)
        #expect(notificationService.setupAllNotificationsBookIDs == (expectedSetupCount == 1 ? [book.id] : []))
        #expect(notificationService.clearRequestsCallCount == 0)
        #expect(viewModel.systemAuthorizationStatus == status)
    }

    @Test("NotiSettingViewModel: C4 설정 앱에서 권한을 허용하고 돌아오면 배너가 사라지고 알림이 다시 등록된다")
    func notiSetting_c4_returnAfterGrantingInSettings_hidesBannerAndReregisters() async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = .denied
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 9, reminderMinute: 0)
        )

        await viewModel.handleScreenEntry()
        #expect(viewModel.isSystemNotificationBannerVisible)

        notificationService.currentStatus = .authorized
        await viewModel.handleReturnToForeground(userBook: makeBook())

        #expect(viewModel.isSystemNotificationBannerVisible == false)
        #expect(notificationService.setupAllNotificationsCallCount == 1)
        #expect(notificationService.requestAuthorizationCallCount == 0)
    }

    @Test("NotiSettingViewModel: C2 진입 팝업이 떠 있는 동안 들어온 복귀 조회가 팝업 결과를 덮지 않는다")
    func notiSetting_c2_returnDuringEntryPrompt_doesNotOverwriteEntryResult() async {
        let notificationService = NotificationManagerStub()
        let promptGate = AsyncGate()
        notificationService.currentStatus = .notDetermined
        notificationService.statusAfterRequest = .denied
        notificationService.requestAuthorizationGate = promptGate
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: SystemSettingsOpenerStub(),
            settingsStore: NotificationSettingsStoreStub(disabled: false, reminderHour: 9, reminderMinute: 0)
        )

        // 진입 처리가 OS 팝업에서 멈춰 있다.
        let entryTask = Task {
            await viewModel.handleScreenEntry()
        }
        #expect(await waitUntil { notificationService.requestAuthorizationCallCount == 1 })

        // 팝업 때문에 앱이 inactive → active가 되면서 복귀 처리가 들어온다. 이 시점의 OS 상태는 아직 미결정이다.
        await viewModel.handleReturnToForeground(userBook: makeBook())

        // 사용자가 거절해 팝업이 닫히면 진입 처리의 최종 결과(거절)가 배너에 반영돼야 한다.
        await promptGate.open()
        await entryTask.value

        #expect(viewModel.systemAuthorizationStatus == .denied)
        #expect(viewModel.isSystemNotificationBannerVisible)
        #expect(notificationService.setupAllNotificationsCallCount == 0)
        #expect(notificationService.requestAuthorizationCallCount == 1)
    }

    @Test("NotiSettingViewModel: 앱 알림을 켜서 권한을 허용하면 배너가 사라진다")
    func notiSetting_enable_afterAuthorizationGranted_refreshesBanner() async {
        let notificationService = NotificationManagerStub()
        notificationService.currentStatus = .denied
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 화면 진입: OS 권한이 아직 허용되지 않아 배너가 보인다.
        await viewModel.handleScreenEntry()
        #expect(viewModel.systemAuthorizationStatus == .denied)

        // 앱 알림을 켜면 권한 팝업이 뜨고, 사용자가 허용한 상황을 가정한다.
        notificationService.currentStatus = .authorized
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())

        #expect(await waitUntil { viewModel.systemAuthorizationStatus == .authorized })

        // 허용한 뒤에는 배너가 남아 있어서는 안 된다.
        #expect(viewModel.systemAuthorizationStatus == .authorized)
        #expect(notificationService.setupAllNotificationsCallCount == 1)
    }

    @Test("NotiSettingViewModel: 뒤늦게 끝난 이전 권한 조회가 최신 배너 상태를 덮어쓰지 않는다")
    func notiSetting_staleAuthorizationResult_doesNotOverwriteLatestState() async {
        let notificationService = NotificationManagerStub()
        let staleAuthorizationGate = AsyncGate()
        notificationService.authorizationStatusResults = [.authorized, .denied]
        notificationService.authorizationStatusGates = [staleAuthorizationGate]
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 첫 조회는 게이트에서 붙잡아 둔다. 풀리면 허용(authorized)을 반환할 예정이다.
        // 취소되는 토글 Task가 아니라 취소되지 않는 진입 경로를 써서 세대 비교만이 이 결과를 막게 한다.
        let staleEntryTask = Task {
            await viewModel.handleScreenEntry()
        }
        #expect(await waitUntil { notificationService.authorizationStatusCallCount == 1 })

        // 두 번째 조회를 먼저 끝낸다. 즉시 거절(denied)을 반환한다.
        viewModel.isNotificationDisabled = true
        viewModel.handleNotificationStatusChange(userBook: makeBook())
        #expect(
            await waitUntil {
                notificationService.authorizationStatusCallCount == 2 &&
                    viewModel.systemAuthorizationStatus == .denied
            }
        )

        // 그다음 첫 조회를 풀고 끝날 때까지 기다린다. 최신 상태(denied)를 되돌려서는 안 된다.
        await staleAuthorizationGate.open()
        await staleEntryTask.value

        #expect(viewModel.systemAuthorizationStatus == .denied)
    }

    @Test("NotiSettingViewModel: 화면 진입 조회가 토글 경로의 최신 배너 상태를 덮어쓰지 않는다")
    func notiSetting_initialAuthorizationResult_doesNotOverwriteToggleState() async {
        let notificationService = NotificationManagerStub()
        let initialAuthorizationGate = AsyncGate()
        notificationService.authorizationStatusResults = [.denied, .authorized]
        notificationService.authorizationStatusGates = [initialAuthorizationGate]
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 화면 진입 조회는 거부(false)를 반환하기 전에 대기한다.
        let initialRefreshTask = Task {
            await viewModel.handleScreenEntry()
        }
        #expect(await waitUntil { notificationService.authorizationStatusCallCount == 1 })

        // 그 사이 토글 경로가 허용(true)을 반영한다.
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())
        #expect(
            await waitUntil {
                notificationService.authorizationStatusCallCount == 2 &&
                    viewModel.systemAuthorizationStatus == .authorized
            }
        )

        // 대기 중이던 진입 조회도 반드시 재개해 끝낸다.
        await initialAuthorizationGate.open()
        await initialRefreshTask.value

        #expect(viewModel.systemAuthorizationStatus == .authorized)
    }

    @Test("NotiSettingViewModel: 권한 팝업 중 화면 복귀 조회 뒤에도 토글의 최신 권한 상태를 반영한다")
    func notiSetting_toggleAuthorizationResult_overwritesRefreshDuringPermissionPrompt() async {
        let notificationService = NotificationManagerStub()
        let permissionPromptGate = AsyncGate()
        notificationService.authorizationStatusResults = [.denied, .authorized]
        notificationService.setupAllNotificationsGate = permissionPromptGate
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 9,
            reminderMinute: 0
        )
        let settingsOpener = SystemSettingsOpenerStub()
        let viewModel = makeNotiSettingViewModel(
            notificationService: notificationService,
            settingsOpener: settingsOpener,
            settingsStore: settingsStore
        )

        // 알림을 켜면 OS 권한 팝업이 열린 상태로 대기한다.
        viewModel.isNotificationDisabled = false
        viewModel.handleNotificationStatusChange(userBook: makeBook())
        #expect(await waitUntil { notificationService.setupAllNotificationsCallCount == 1 })

        // 팝업이 열린 사이 화면이 복귀하면서 거부(false) 상태를 조회한다.
        await viewModel.handleScreenEntry()
        #expect(viewModel.systemAuthorizationStatus == .denied)

        // 사용자가 권한을 허용해 팝업을 닫으면 토글 경로의 최종 조회는 허용(true)이다.
        await permissionPromptGate.open()
        #expect(await waitUntil { viewModel.systemAuthorizationStatus == .authorized })
        #expect(notificationService.authorizationStatusCallCount == 2)
    }
}
