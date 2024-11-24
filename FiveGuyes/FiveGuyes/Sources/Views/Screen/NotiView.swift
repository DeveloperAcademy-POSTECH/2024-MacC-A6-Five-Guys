//
//  NotiView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/21/24.
//

import SwiftData
import SwiftUI

struct NotiView: View {
    
    @State private var isToggleOn: Bool = false
    @State private var selectedStartTime: Date = Date() // 하루 시작 알림 시간
    @State private var selectedReminderTime: Date = Date() // 리마인더 알림 시간
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    @State private var isReminderTimePickerVisible: Bool = false
    @State private var isStartTimePickerVisible: Bool = false
    
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Toggle("모든 알림 수신", isOn: $isToggleOn)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .toggleStyle(SwitchToggleStyle(tint: isToggleOn ? Color(red: 0.2, green: 0.78, blue: 0.35): Color(red: 0.47, green: 0.47, blue: 0.5).opacity(0.16)))
                Text("독서 알림이 모두 수신돼요.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
            }
            .padding(16)
            .background(Color(red: 0.96, green: 0.98, blue: 0.97))
            .cornerRadius(16)
            .animation(.easeInOut, value: isToggleOn) // 애니메이션 추가
            .onChange(of: isToggleOn)  { isOn in
                if isOn, let userBook = currentlyReadingBooks.first {
                    setNotifications(for: userBook)
                    
                }  else {
                    notificationManager.clearRequests()
                }
            }
            if isToggleOn {
                ScrollView {
                    VStack {// 하루 독서 시작 알림
                                timePickerSection (
                                    title: "하루 독서 시작 알림",
                                    description: "지정된 시간에 오늘의 독서 목표를 알릴게요.",
                                    selectedTime: $selectedStartTime,
                                    isPickerVisible: $isStartTimePickerVisible,
                                    allowedRange: nil
                                )
                                .onChange(of: selectedStartTime) { newStartTime in
                                    UserDefaults.standard.set(newStartTime, forKey: "selectedStartTime")
                                                                if let userBook = currentlyReadingBooks.first {
                                                                    setNotifications(for: userBook) // 시간 변경 시 알림 설정
                                                                }
                                    
                                }
                                Rectangle()
                                    .frame(width: 365, height: 1)
                                    .foregroundColor(Color(red: 0.94, green: 0.94, blue: 0.94))
                                // 하루 독서 미완료 알림
                                timePickerSection (
                                    title: "하루 독서 미완료 알림",
                                    description: "지정된 시간까지 독서하지 않으면 알릴게요.",
                                    selectedTime: $selectedReminderTime,
                                    isPickerVisible: $isReminderTimePickerVisible,
                                    allowedRange: allowedRange
                                )
                                .onChange(of: selectedReminderTime) { newReminderTime in
                                    UserDefaults.standard.set(newReminderTime, forKey: "selectedReminderTime")
                                                               if let userBook = currentlyReadingBooks.first {
                                                                   setNotifications(for: userBook) // 시간 변경 시 알림 설정
                                                               }
                                }
                            
                        }
                        
                    }
            } else {
                Spacer()
            }
                
                } .onAppear {
                    selectedStartTime = UserDefaults.standard.object(forKey: "selectedStartTime") as? Date
                                  ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
                              selectedReminderTime = UserDefaults.standard.object(forKey: "selectedReminderTime") as? Date
                                  ?? Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
                              isToggleOn = UserDefaults.standard.bool(forKey: "isToggleOn")
                }
            }
          
            // TODO: 현재 로직상으로는 책이 있어야만 알람설정이 가능 - 알려줘야하지 않을까?
        
       

    
    // MARK: - Time Picker Section
    private func timePickerSection(
        title: String,
        description: String,
        selectedTime: Binding<Date>,
        isPickerVisible: Binding<Bool>,
        allowedRange: ClosedRange<Date>?
    ) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                timeDisplay(selectedTime: selectedTime, isPickerVisible: isPickerVisible)
                    .onChange(of: selectedTime.wrappedValue) { oldValue, newValue in
                        print("📆 DatePicker Selected Time (KST): \(newValue)")
                    }
            }
            Text(description)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
            if isPickerVisible.wrappedValue {
                timePicker(selectedTime: selectedTime, allowedRange: allowedRange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    private func timeDisplay(selectedTime: Binding<Date>, isPickerVisible: Binding<Bool>) -> some View {
        HStack {
            Text(selectedTime.wrappedValue, style: .time)
                .font(.system(size: 16, weight: .light))
                .multilineTextAlignment(.center)
                .frame(width: 80, alignment: .center)
                .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
        }
        .padding(.vertical, 3)
        .background(Color(red: 0.96, green: 0.98, blue: 0.97))
        .cornerRadius(6)
        .onTapGesture {
            withAnimation {
                isPickerVisible.wrappedValue.toggle()
            }
        }
    }
    
    private func timePicker(selectedTime: Binding<Date>, allowedRange: ClosedRange<Date>?) -> some View {
        VStack {
            if let range = allowedRange {
                DatePicker(
                    "",
                    selection: selectedTime,
                    in: range,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
            } else {
                DatePicker(
                    "",
                    selection: selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
            }
        }
        .transition(.scale(scale: 1, anchor: .top).combined(with: .opacity))
        .animation(.easeInOut)
    }
    
    // 리마인더 알림 시간 범위
    var allowedRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let timeZone = TimeZone(identifier: "Asia/Seoul")! // 한국 시간대 설정
        var calendarInKST = calendar
        calendarInKST.timeZone = timeZone // Calendar를 KST로 설정
        
        let now = Date()
        
        // KST 기준으로 오늘 자정과 오전 4시 계산
        let startOfDay = calendarInKST.startOfDay(for: now)
        
        let fourAMToday = calendarInKST.date(byAdding: .hour, value: 4, to: startOfDay)!
        let fourAMTomorrow = calendarInKST.date(byAdding: .hour, value: 28, to: startOfDay)!
        let beforeStartNotification = selectedStartTime.addingTimeInterval(-1)
        // 하루 시작 알림 시간 후
        let afterStartNotification = selectedStartTime.addingTimeInterval(1)
        
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        // 리마인더 알림 시간은 하루 시작 알림 전후로 나눔
        if selectedStartTime > fourAMToday {
            // 오전 4시 ~ 하루 시작 알림 전, 또는 하루 시작 알림 후 ~ 자정 전
            return fourAMToday...beforeStartNotification
        } else {
            return afterStartNotification...endOfDay
        }
    }
    
    private func setNotifications(for userBook: UserBook) {
           Task {
               await notificationManager.setupNotifications(notificationType: .morning(readingBook: userBook), selectedTime: selectedStartTime)
               await notificationManager.setupNotifications(notificationType: .night(readingBook: userBook), selectedTime: selectedReminderTime)
           }
       }
     // 모든 알림 취소
    private func cancelAllNotifications() {
        notificationManager.clearRequests()
    }
    private func convertToUTC(_ date: Date) -> Date {
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let timeZoneOffset = timeZone.secondsFromGMT(for: date)
        return date.addingTimeInterval(-TimeInterval(timeZoneOffset))
    }
    private func convertToKST(_ date: Date) -> Date {
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let timeZoneOffset = timeZone.secondsFromGMT(for: date)
        return date.addingTimeInterval(TimeInterval(timeZoneOffset))
    }
}

#Preview {
    NotiView()
}
