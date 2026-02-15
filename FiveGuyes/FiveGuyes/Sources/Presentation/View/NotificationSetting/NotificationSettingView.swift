//
//  NotificationSettingView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/27/24.
//

import SwiftUI

struct NotificationSettingView: View {
    @Environment(\.scenePhase) private var scenePhase // 앱 상태 감지

    @State private var viewModel: NotificationSettingViewModel
    let userBook: FGUserBook?

    init(userBook: FGUserBook?, viewModel: NotificationSettingViewModel) {
        self.userBook = userBook
        self._viewModel = State(initialValue: viewModel)
    }
    
    // Toggle 바인딩 변수
    private var isNotificationToggleEnabled: Binding<Bool> {
        Binding(
            get: { !viewModel.isNotificationDisabled },
            set: { viewModel.isNotificationDisabled = !$0 }
        )
    }
    
    var body: some View {
        ZStack {
            Color.Fills.white // 배경색 지정
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: .zero) {
                if !viewModel.isSystemNotificationEnabled {
                    notificationDisabledView
                }
                
                toggleSection
                
                dividerLine
                    .padding(.top, 12)
                
                // 하루 독서 미완료 알림
                timePickerSection
                    .padding(.top, 16)
                
                if viewModel.isReminderTimePickerVisible {
                    timePicker
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .navigationTitle("알림 설정")
        .customNavigationBackButton()
        .task {
            await viewModel.refreshSystemNotificationAuthorization()
        }
        .onAppear {
            viewModel.loadPersistedSettings()
        }
        .onChange(of: viewModel.isNotificationDisabled) {
            viewModel.handleNotificationStatusChange(userBook: userBook)
        }
        .onChange(of: viewModel.selectedTime) {
            viewModel.handleNotificationTimeChange(userBook: userBook)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { // 시스템 설정에 갔다가 다시 오는 상황 체크
                Task {
                    await viewModel.refreshSystemNotificationAuthorization()
                }
            }
        }
    }
    
    // MARK: - View Property
    private func primaryTitle(_ title: String) -> some View {
        Text(title)
            .fontStyle(.title2, weight: .semibold)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .multilineTextAlignment(.leading)
    }
    
    private func secondaryTitle(_ title: String) -> some View {
        Text(title)
            .fontStyle(.body)
            .foregroundStyle(Color.Labels.secondaryBlack2)
            .multilineTextAlignment(.leading)
    }
    
    private var notificationDisabledView: some View {
        Button(action: SystemSettingsManager.openSettings) {
            HStack {
                VStack(alignment: .leading, spacing: .zero) {
                    primaryTitle("기기의 알림 설정이 꺼져 있어요!")
                    secondaryTitle("설정을 변경하고, 완독에 도움이 되는 알림을\n받아보세요")
                }
                .padding(.leading, 16)
                
                Spacer()
                
                Image(systemName: "chevron.forward")
                    .frame(width: 15, height: 22)
                    .scaledToFit()
                    .foregroundStyle(Color.Colors.green2)
                    .padding(.trailing, 12)
            }
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color.Fills.lightGreen)
            }
            .padding(.bottom, 32)
        }
    }
    
    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Toggle("알림 끄기", isOn: isNotificationToggleEnabled)
                .toggleStyle(.switch)
                .fontStyle(.title2, weight: .semibold)
                .foregroundStyle(Color.Labels.primaryBlack1)
            
            secondaryTitle("한입독서와 관련된 알림 수신이 중단돼요")
        }
    }
    
    private var dividerLine: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(Color.Separators.gray)
    }
    
    // 데이터 피커를 포함한 섹션
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                primaryTitle("리마인드 알림")
                Spacer()
                timerPickerButton
            }
            secondaryTitle("지정된 시간에 오늘의 독서 목표를 알릴게요")
        }
    }
    
    private var timerPickerButton: some View {
        Button {
            withAnimation(.easeIn) {
                viewModel.isReminderTimePickerVisible.toggle()
            }
        } label: {
            Text(viewModel.selectedTime, style: .time)
                .fontStyle(.body)
                .foregroundStyle(Color.Colors.green2)
                .multilineTextAlignment(.center)
                .frame(width: 80, alignment: .center)
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(Color.Fills.lightGreen)
        }
    }
    
    // 실제로 데이터 피커가 보이는곳에 쓰이는 피커 컴포넌트
    private var timePicker: some View {
        @Bindable var bindableViewModel = viewModel
        return VStack {
            DatePicker(
                "",
                selection: $bindableViewModel.selectedTime,
                in: viewModel.timeSelectionRange,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
        }
        .transition(.scale(scale: 1, anchor: .top).combined(with: .opacity))
        .onAppear {
            UIDatePicker.appearance().minuteInterval = 5
        }
        .onDisappear {
            UIDatePicker.appearance().minuteInterval = 1
        }
    }
}

#if DEBUG
// 이 프리뷰는 "기본 상태" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("기본 상태") {
    NavigationStack {
        NotificationSettingView(
            userBook: PreviewSupport.sampleReadingBook,
            viewModel: makeNotificationSettingPreviewViewModel()
        )
    }
}

// 이 프리뷰는 "시스템 알림 비활성화" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("시스템 알림 비활성화") {
    NavigationStack {
        NotificationSettingView(
            userBook: PreviewSupport.sampleReadingBook,
            viewModel: makeNotificationSettingPreviewViewModel(isSystemNotificationEnabled: false)
        )
    }
}

// 이 프리뷰는 "리마인드 시간 피커 열림" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("리마인드 시간 피커 열림") {
    NavigationStack {
        NotificationSettingView(
            userBook: PreviewSupport.sampleReadingBook,
            viewModel: makeNotificationSettingPreviewViewModel(
                isNotificationDisabled: true,
                isReminderTimePickerVisible: true
            )
        )
    }
}

// 화면 값은 메인 스레드에서만 바꿔야 안전합니다.
// 이 표시를 붙여, 다른 스레드가 끼어들어 상태가 꼬이는 일을 막습니다.
@MainActor
// 알림 화면 검증에 필요한 권한, 토글, 시간 값을 한 번에 만드는 헬퍼입니다.
// 값이 흩어지면 같은 시나리오를 다시 만들기 어려워집니다.
private func makeNotificationSettingPreviewViewModel(
    isSystemNotificationEnabled: Bool = true,
    isNotificationDisabled: Bool = false,
    isReminderTimePickerVisible: Bool = false
) -> NotificationSettingViewModel {
    let notificationService = PreviewNotificationManager()
    notificationService.isAuthorized = isSystemNotificationEnabled

    let settingsStore = PreviewNotificationSettingsStore(
        isDisabled: isNotificationDisabled,
        reminderHour: 8,
        reminderMinute: 30
    )

    let viewModel = NotificationSettingViewModel(
        notificationService: notificationService,
        settingsStore: settingsStore
    )
    viewModel.isSystemNotificationEnabled = isSystemNotificationEnabled
    viewModel.isNotificationDisabled = isNotificationDisabled
    viewModel.isReminderTimePickerVisible = isReminderTimePickerVisible
    viewModel.loadPersistedSettings()
    viewModel.isReminderTimePickerVisible = isReminderTimePickerVisible
    return viewModel
}
#endif
