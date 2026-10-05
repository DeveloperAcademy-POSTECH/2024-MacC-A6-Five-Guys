//
//  NotiSettingViewModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotiSettingViewModel {
    var selectedTime: Date = Date()
    var isNotificationDisabled = false
    var isReminderTimePickerVisible = false
    var systemAuthorizationStatus: NotificationAuthorizationStatus = .authorized

    private var notificationStatusTask: Task<Void, Never>?
    private var notificationTimeTask: Task<Void, Never>?
    private var systemAuthorizationRefreshGeneration = 0
    private var isHandlingScreenEntry = false

    private let notificationSettingUseCase: any NotificationSettingUsing
    private let nowProvider: () -> Date

    init(
        notificationSettingUseCase: any NotificationSettingUsing,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.notificationSettingUseCase = notificationSettingUseCase
        self.nowProvider = nowProvider
    }

    var isSystemNotificationBannerVisible: Bool {
        !isNotificationDisabled && systemAuthorizationStatus == .denied
    }

    var timeSelectionRange: ClosedRange<Date> {
        let calendar = Calendar.app
        let now = nowProvider()
        let startOfDay = calendar.startOfDay(for: now)
        let start = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: startOfDay) ?? now
        let end = calendar.date(bySettingHour: 23, minute: 55, second: 0, of: startOfDay) ?? now
        return start...end
    }

    func loadPersistedSettings() {
        let snapshot = notificationSettingUseCase.loadSnapshot(now: nowProvider())
        selectedTime = snapshot.selectedTime
        isNotificationDisabled = snapshot.isNotificationDisabled
    }

    func setNotificationDisabled(_ isDisabled: Bool, userBook: FGUserBook?) {
        isNotificationDisabled = isDisabled
        handleNotificationStatusChange(userBook: userBook)
    }

    func updateReminderTime(_ time: Date, userBook: FGUserBook?) {
        selectedTime = time
        handleNotificationTimeChange(userBook: userBook)
    }

    func handleScreenEntry() async {
        isHandlingScreenEntry = true
        defer { isHandlingScreenEntry = false }

        let generation = beginSystemAuthorizationRefresh()
        let status = await notificationSettingUseCase.prepareAuthorizationOnEntry()
        updateSystemAuthorizationStatus(status, for: generation)
    }

    func handleReturnToForeground(userBook: FGUserBook?) async {
        // 진입 처리 중 OS 팝업 때문에 들어온 복귀는 건너뛴다. 진입 처리가 팝업 이후의 최종 상태를 반영한다.
        guard !isHandlingScreenEntry else { return }

        let generation = beginSystemAuthorizationRefresh()
        let status = await notificationSettingUseCase.refreshAuthorizationOnReturn(userBook: userBook)
        updateSystemAuthorizationStatus(status, for: generation)
    }

    func handleNotificationStatusChange(userBook: FGUserBook?) {
        notificationStatusTask?.cancel()
        let isDisabled = isNotificationDisabled

        notificationStatusTask = Task {
            guard !Task.isCancelled else { return }
            await notificationSettingUseCase.setNotificationDisabled(isDisabled, userBook: userBook)

            // 앱 알림을 켜는 순간 OS 권한 팝업이 뜰 수 있고, 그 결과가 배너 표시를 좌우한다.
            // 진입 시 읽은 상태는 이 팝업 이전 값이라 여기서 다시 읽어야 한다.
            guard !Task.isCancelled else { return }
            let generation = beginSystemAuthorizationRefresh()
            let status = await notificationSettingUseCase.refreshSystemAuthorization()

            // 조회가 취소를 관찰하지 않을 수 있으므로, 대입 직전에 최신 조회인지 다시 확인한다.
            // 그러지 않으면 뒤늦게 끝난 이전 조회가 최신 결과를 덮어쓴다.
            guard !Task.isCancelled else { return }
            updateSystemAuthorizationStatus(status, for: generation)
        }
    }

    func handleNotificationTimeChange(userBook: FGUserBook?) {
        notificationTimeTask?.cancel()
        let currentSelectedTime = selectedTime
        let isDisabled = isNotificationDisabled

        notificationTimeTask = Task {
            guard !Task.isCancelled else { return }
            await notificationSettingUseCase.updateReminderTime(
                currentSelectedTime,
                isNotificationDisabled: isDisabled,
                userBook: userBook
            )
        }
    }

    func openSystemSettings() {
        notificationSettingUseCase.openSystemSettings()
    }

    private func beginSystemAuthorizationRefresh() -> Int {
        systemAuthorizationRefreshGeneration += 1
        return systemAuthorizationRefreshGeneration
    }

    private func updateSystemAuthorizationStatus(_ status: NotificationAuthorizationStatus, for generation: Int) {
        guard generation == systemAuthorizationRefreshGeneration else { return }
        systemAuthorizationStatus = status
    }
}
