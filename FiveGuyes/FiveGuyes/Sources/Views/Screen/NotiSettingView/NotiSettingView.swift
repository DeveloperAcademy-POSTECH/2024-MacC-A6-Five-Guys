//
//  NotiSettingView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/27/24.
//

import SwiftData
import SwiftUI

struct NotiSettingView: View {
    @State private var isNotiDisabled: Bool = false // 모든 알람 수신 토글
    @State private var selectedTime: Date = Date() // 데이트 피커에 사용될 시간
    @State private var isReminderTimePickerVisible: Bool = false // 데이트 피커 표시 여부
    
    // TODO: 실제 노티 설정 값 불러오기
    @State private var isNotificationDisabled = true
    
    var body: some View {
        ZStack {
            Color.white // 배경색 지정
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: .zero) {
                if isNotificationDisabled {
                    notificationDisabledView
                }
                
                VStack(alignment: .leading, spacing: .zero) {
                    Toggle("알림 끄기", isOn: $isNotiDisabled)
                        .toggleStyle(.switch)
                        .fontStyle(.title2, weight: .semibold)
                        .foregroundStyle(Color.Labels.primaryBlack1)
                    secondaryTitle("한입독서와 관련된 알림 수신이 중단돼요")
                }
                
                Rectangle()
                    .stroke(lineWidth: 2)
                    .frame(height: 1)
                    .foregroundStyle(Color.Separators.gray)
                    .padding(.top, 12)
                
                // 하루 독서 미완료 알림
                timePickerSection(
                    title: "리마인드 알림",
                    description: "지정된 시간에 오늘의 독서 목표를 알릴게요",
                    selectedTime: $selectedTime,
                    isPickerVisible: $isReminderTimePickerVisible,
                    allowedRange: timeSelectionRange
                )
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .navigationTitle("알림 설정")
        .onChange(of: isNotiDisabled) {
            UserDefaults.standard.set(isNotiDisabled, forKey: UserDefaultsKeys.isNotificationDisabled.rawValue)
        }
        .onChange(of: selectedTime) {
            saveTime(selectedTime) // 시간과 분 저장
        }
        .onAppear {
            loadInitialTime()
            isNotiDisabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isNotificationDisabled.rawValue)
        }
    }
    
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
        Button {
            // TODO: 노티 설정 화면으로 넘어가기
            withAnimation(.easeIn) {
                isNotificationDisabled.toggle()
            }
        } label: {
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
    
    // 데이터 피커를 포함한 알림 리스트 row
    private func timePickerSection (
        title: String,
        description: String,
        selectedTime: Binding<Date>,
        isPickerVisible: Binding<Bool>,
        allowedRange: ClosedRange<Date>
    ) -> some View {
        
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                primaryTitle(title)
                
                Spacer()
                
                Button {
                    withAnimation(.easeIn) {
                        isPickerVisible.wrappedValue.toggle()
                    }
                } label: {
                    Text(selectedTime.wrappedValue, style: .time)
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
            
            secondaryTitle(description)
            
            if isPickerVisible.wrappedValue {
                timePicker(selectedTime: selectedTime, allowedRange: allowedRange)
            }
        }
    }
    
    // 실제로 데이터 피커가 보이는곳에 쓰이는 피커 컴포넌트
    private func timePicker(selectedTime: Binding<Date>, allowedRange: ClosedRange<Date>) -> some View {
        VStack {
            DatePicker(
                "",
                selection: selectedTime,
                in: allowedRange,
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
    
    // 시간 범위 설정: 04:00 ~ 23:55
    private var timeSelectionRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let start = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: startOfDay)!
        let end = calendar.date(bySettingHour: 23, minute: 55, second: 0, of: startOfDay)!
        return start...end
    }
    
    // 시간과 분만 저장
    private func saveTime(_ time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        print("Save: \(hour): \(minute)")
        UserDefaults.standard.set(hour, forKey: UserDefaultsKeys.reminderHour.rawValue)
        UserDefaults.standard.set(minute, forKey: UserDefaultsKeys.reminderMinute.rawValue)
    }
    
    // 저장된 시간과 분 불러오기
    private func loadInitialTime() {
        let calendar = Calendar.current
        let hour = UserDefaults.standard.integer(forKey: UserDefaultsKeys.reminderHour.rawValue) // 저장된 시간
        let minute = UserDefaults.standard.integer(forKey: UserDefaultsKeys.reminderMinute.rawValue) // 저장된 분
        
        if hour != 0 || minute != 0 { // 저장된 값이 있을 경우
            selectedTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        } else { // 기본값 설정 (오후 9:00)
            selectedTime = calendar.date(bySettingHour: 09, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
}

#Preview {
    NavigationStack {
        NotiSettingView()
    }
}
