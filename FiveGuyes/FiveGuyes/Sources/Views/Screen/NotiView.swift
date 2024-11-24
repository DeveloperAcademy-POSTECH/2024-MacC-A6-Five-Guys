//
//  NotiView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/21/24.
//

import SwiftData
import SwiftUI

struct NotiView: View {
    
    @State private var isToggleOn: Bool = false // 모든 알람 수신 토글
    @State private var selectedStartTime: Date = Date() // 하루 시작 알림 시간
    @State private var selectedReminderTime: Date = Date() // 리마인더 알림 시간
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    @State private var isReminderTimePickerVisible: Bool = false // 시작 알람설정 데이트 피커 보이기 플래그
    @State private var isStartTimePickerVisible: Bool = false // 리마인더 알람설정 데이트 피커 보이기 플래그
    
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
            .onChange(of: isToggleOn) {
                UserDefaults.standard.set(isToggleOn, forKey: "isToggleOn")
                if isToggleOn, let userBook = currentlyReadingBooks.first {
                    setNotifications(for: userBook)
                    
                } else {
                    notificationManager.clearRequests()
                }
            }
            if isToggleOn {
                ScrollView {
                    VStack {// 하루 독서 시작 알림
                        timePickerSection(
                            title: "하루 독서 시작 알림",
                            description: "지정된 시간에 오늘의 독서 목표를 알릴게요.",
                            selectedTime: $selectedStartTime,
                            isPickerVisible: $isStartTimePickerVisible,
                            allowedRange: startNotificationRange
                        )
                        .onChange(of: selectedStartTime) {
                            UserDefaults.standard.set(selectedStartTime, forKey: "selectedStartTime")
                            if let userBook = currentlyReadingBooks.first {
                                setNotifications(for: userBook) // 시간 변경 시 알림 설정
                            }
                        }
                        Rectangle()
                            .frame(width: 365, height: 1)
                            .foregroundColor(Color(red: 0.94, green: 0.94, blue: 0.94))
                        // 하루 독서 미완료 알림
                        timePickerSection(
                            title: "하루 독서 미완료 알림",
                            description: "지정된 시간까지 독서하지 않으면 알릴게요.",
                            selectedTime: $selectedReminderTime,
                            isPickerVisible: $isReminderTimePickerVisible,
                            allowedRange: reminderNotificationRange
                        )
                        .onChange(of: selectedReminderTime) {
                            UserDefaults.standard.set(selectedReminderTime, forKey: "selectedReminderTime")
                            if let userBook = currentlyReadingBooks.first {
                                setNotifications(for: userBook) // 시간 변경 시 알림 설정
                            }
                        }
                        
                    }
                    
                }
            } else {
                Spacer()
            }
        }
        // 뒤로가기를 해서 다시 오더라도 데이터가 저장되게 해줌 (다시 뷰를 그리면서 동작)
        .onAppear {
            selectedStartTime = UserDefaults.standard.object(forKey: "selectedStartTime") as? Date
            ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            selectedReminderTime = UserDefaults.standard.object(forKey: "selectedReminderTime") as? Date
            ?? Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
            isToggleOn = UserDefaults.standard.bool(forKey: "isToggleOn")
            
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // TODO: 현재 로직상으로는 책이 있어야만 알람설정이 가능 하지만 책이 없을때도 알람 설정 가능 노티창이 보임 - 이 사실을 미리 알려줘야하지 않을까?
    
    // 데이터 피커를 포함한 알림 리스트 row
    private func timePickerSection (title: String, description: String, selectedTime: Binding<Date>, isPickerVisible: Binding<Bool>, allowedRange: ClosedRange<Date>
    ) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
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
            Text(description)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
            if isPickerVisible.wrappedValue {
                timePicker(selectedTime: selectedTime, allowedRange: allowedRange)
            }
        }
        .padding(.leading, 12)
        .padding(.vertical, 12)
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
        .animation(.easeInOut)
    }
    
    // 데이트 피커 시간범위 설정 코드
    // 시작 알람 시간 범위 설정 : 오전 04:00~오후 23:59
    var startNotificationRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        // 시간의 정확한 판단을 위해 convertToKST로 바꿔놓고 시작
        let startOfDay = convertToKST(calendar.startOfDay(for: now)) // 자정
        let fourAMToday = calendar.date(byAdding: .hour, value: 4, to: startOfDay)! // 오늘 오전 04:00
        let startNotificationMax = convertToKST(calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!)
        
        print("⏰스타트 알림 범위 : \(fourAMToday...startNotificationMax)")
        // 데이트 피커는 allowedRange를 UTC 기준으로 판단하기 때문에 변경필요
        return convertToUTC(fourAMToday)...convertToUTC(startNotificationMax)
    }

    // 리마인더 알림 시간 범위설정 : 하루시작알림 +1분 ~ 오전 03:59
    var reminderNotificationRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        // KST 기준으로 오늘 자정과 오전 4시 계산
        let startOfDay = convertToKST(calendar.startOfDay(for: now)) // 자정
        let fourAMTomorrow = calendar.date(byAdding: .hour, value: 28, to: startOfDay)! // 다음 날 오전 04:00
        
        // 리마인더 알림 시간
        // selectedStartTime은 UTC 기준으로받아지므로 따로 변경필요 없음
        let reminderStart = (selectedStartTime).addingTimeInterval(60) // 하루 시작 알림 + 1분
        // 데이트 피커는 allowedRange를 UTC 기준으로 판단하기 때문에 변경필요
        let reminderEnd = convertToUTC(fourAMTomorrow.addingTimeInterval(-60)) // 다음 날 오전 03:59

        print("⏰리마인더 알림 범위 : \(convertToKST(reminderStart)...convertToKST(reminderEnd))")
        return (reminderStart)...(reminderEnd)
    }

    // 노티 셋팅 - 기존 매니저 활용
    private func setNotifications(for userBook: UserBook) {
        Task {
            await notificationManager.setupNotifications(notificationType: .morning(readingBook: userBook), selectedTime: selectedStartTime)
            await notificationManager.setupNotifications(notificationType: .night(readingBook: userBook), selectedTime: selectedReminderTime)
            notificationManager.printPendingNotifications()
        }
    }
    
    // 데이트 피커에 보이는 범위(레인지 설정)을 위한 kst - utc 시간 zone 변경 함수
    private func convertToUTC(_ date: Date) -> Date {
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let timeZoneOffset = timeZone.secondsFromGMT(for: date)
        return date.addingTimeInterval(-TimeInterval(timeZoneOffset))
    }
    
    // 데이트 피커에 보이는 범위(레인지 설정)을 위한 kst - utc 시간 zone 변경 함수
    private func convertToKST(_ date: Date) -> Date {
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let timeZoneOffset = timeZone.secondsFromGMT(for: date)
        return date.addingTimeInterval(TimeInterval(timeZoneOffset))
    }
}

#Preview {
    NotiView()
}
