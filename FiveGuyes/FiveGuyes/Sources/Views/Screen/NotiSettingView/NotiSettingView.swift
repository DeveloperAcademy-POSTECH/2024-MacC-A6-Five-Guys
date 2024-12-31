//
//  NotiSettingView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/27/24.
//

import SwiftData
import SwiftUI

struct NotiSettingView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @Environment(\.scenePhase) private var scenePhase // 앱 상태 감지
    
    @State private var selectedTime: Date = Date() // 데이트 피커에 사용될 시간
    
    @State private var isNotificationDisabled: Bool = false // 모든 알람 수신 토글
    @State private var isReminderTimePickerVisible: Bool = false // 데이트 피커 표시 여부
    @State private var isSystemNotificationEnabled = true // 시스템 노티 권한 여부
    
    @State private var notificationStatusTask: Task<Void, Never>?
    @State private var notificationTimeTask: Task<Void, Never>?
    
    @Query(filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    private let notificationManager = NotificationManager()
    
    // Toggle 바인딩 변수
    private var isNotificationToggleEnabled: Binding<Bool> {
        Binding(
            get: { !isNotificationDisabled },
            set: { isNotificationDisabled = !$0 }
        )
    }
    
    // 시간 범위 설정: 04:00 ~ 23:55
    private var timeSelectionRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let start = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: startOfDay)!
        let end = calendar.date(bySettingHour: 23, minute: 55, second: 0, of: startOfDay)!
        return start...end
    }
    
    var body: some View {
        let userBook = currentlyReadingBooks.first
        
        ZStack {
            Color.Fills.white // 배경색 지정
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: .zero) {
                if !isSystemNotificationEnabled {
                    notificationDisabledView
                }
                
                toggleSection
                
                dividerLine
                    .padding(.top, 12)
                
                // 하루 독서 미완료 알림
                timePickerSection
                    .padding(.top, 16)
                
                if isReminderTimePickerVisible {
                    timePicker
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .navigationTitle("알림 설정")
        .task {
            isSystemNotificationEnabled = await notificationManager.requestAuthorization()
        }
        .onAppear {
            fetchNotificationTime()
            fetchNotificationDisabled()
        }
        .onChange(of: isNotificationDisabled) {
            // 기존 Task 취소
            notificationStatusTask?.cancel()
            
            // 새로운 Task 생성
            notificationStatusTask = Task {
                await handleNotificationStatusChange(isDisabled: isNotificationDisabled, userBook: userBook)
            }
        }
        .onChange(of: selectedTime) {
            // 기존 Task 취소
            notificationTimeTask?.cancel()
            
            // 새로운 Task 생성
            notificationTimeTask = Task {
                await handleNotificationTimeChange(newTime: selectedTime, userBook: userBook)
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { // 시스템 설정에 갔다가 다시 오는 상황 체크
                Task {
                    isSystemNotificationEnabled = await notificationManager.requestAuthorization()
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
                isReminderTimePickerVisible.toggle()
            }
        } label: {
            Text(selectedTime, style: .time)
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
        VStack {
            DatePicker(
                "",
                selection: $selectedTime,
                in: timeSelectionRange,
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
    
    // MARK: - Method
    // 시간과 분만 저장
    private func saveNotificationTime(_ time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        print("Save: \(hour): \(minute)")
        
        UserDefaultsManager.saveNotificationTime(hour: hour, minute: minute)
    }
    
    private func saveNotificationStatus(_ isNotificationDisabled: Bool) {
        UserDefaultsManager.saveNotificationDisabled(isNotificationDisabled)
    }
    
    // 저장된 시간과 분 불러오기
    private func fetchNotificationTime() {
        let calendar = Calendar.current
        let (hour, minute) = UserDefaultsManager.fetchNotificationReminderTime()
        
        selectedTime =
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
    
    private func fetchNotificationDisabled() {
        isNotificationDisabled = UserDefaultsManager.fetchNotificationDisabled()
    }
    
    private func handleNotificationStatusChange(isDisabled: Bool, userBook: UserBook?) async {
        saveNotificationStatus(isDisabled)
        
        // 등록된 책이 없을 때는 노티 설정 X
        guard let userBook else { return }
        
        if isDisabled {
            await notificationManager.clearRequests()
        } else {
            await notificationManager.setupAllNotifications(userBook)
        }
    }
    
    private func handleNotificationTimeChange(newTime: Date, userBook: UserBook?) async {
        saveNotificationTime(newTime)
        
        // 등록된 책이 없을 때는 노티 설정 X
        guard let userBook else { return }
        
        await notificationManager.updateNotification(notificationType: .morning(readingBook: userBook))
    }
}

#Preview {
    NavigationStack {
        NotiSettingView()
    }
}
