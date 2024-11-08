//
//  PushNotificationTest.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/8/24.
//

import SwiftUI
import UserNotifications



// 노티피케이션 테스트용 매니저
class NotificationManager {
    // 싱글톤 설정
    
    static let shared = NotificationManager()
    
    /// 초기 알람 설정을 위한 권한 호출
    func requestNotificationPermission() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { suceess, error in
            if let error {
                print("알람 권한 호출에 문제가 있어요 에러: \(error)")
            } else {
                print("성공적으료 알람을 위한 권한을 호출했어요")
            }
        }
    }
    
    // 특정 시간 알람
    func scheduleSpecificTimeNotification(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "특정시간알람"
        content.body = "오늘도 꼭 완독하세요!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "specificTimeNoti", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("특정 시간 알람이 설정 되지 않았어요 \(error)")
            } else {
                print("특정 시간 알람을 설정했어요")
            }
        }
    }
    
    
    func scheduleReminderNotification(readingData: [PushNotificationTestView.ReadingData], todayDate: String, hour: Int, minute: Int) {
        guard let todayReadingData = readingData.first(where: { $0.date == todayDate }) else {
            print("오늘 독서관련 데이터를 불러오지 못했어요")
            return
        }
        
        guard todayReadingData.targetPages != nil, (todayReadingData.todayReadPages == nil || todayReadingData.todayReadPages == 0) else {
            print("이미 오늘 페이지를 읽었거나 읽기로 계획한 날이 아니라 알람을 셋팅할 수 없어요")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "리마인더 알람"
        content.body = "오늘 완독하지 않았어요! 완독이가 물어버릴거에요 🥎 왕왕"
        content.sound = .default
        
        
        // 내가 제공한 오늘 날짜(todayDate)에 맞는 연,월,일에 알람이 트리거 되도록 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: todayDate) else {
            print("오늘 날짜를 유효하게 받아오지 못했어요")
            return
        }
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // 설정대로 트리거, 요청 셋팅
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "reminderNoti", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("리마인더 알람을 제대로 설정하지 못했어요. 에러: \(error)")
            } else {
                print("리마인더 알람을 설정했어요")
            }
        }
    }
    
    // 1분 알람 설정
    func scheduleOneMinuteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "1분 후 알람"
        content.body = "설정하고 1분 후에 울렸어요"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(identifier: "oneMinuteNoti", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("1분후 알람을 제대로 설정하지 못했어요. 에러: \(error)")
            } else {
                print("1분 후 알람을 설정했어요")
            }
        }
    }
    
    
    // 한번에 설정하는 함수
    func setupNotifications(readingData: [PushNotificationTestView.ReadingData], todayDate: String, hour: Int, minute: Int) {
        
        requestNotificationPermission()    // 알람 요청
        scheduleSpecificTimeNotification(hour: hour, minute: minute)   // 특정시간 알람 셋팅
        scheduleReminderNotification(readingData: readingData, todayDate: todayDate, hour: hour, minute: minute) // 리마인더 알람 셋팅
        scheduleOneMinuteNotification() // 1분 후 알람 셋팅
    }
}

struct PushNotificationTestView: View {
    @State private var notificationText: String = ""
    let hour: Int = 16
    let minute: Int = 13
    let todayDate = "2024-11-08" // 내가 오늘이라고 테스팅을 위해 사용할 날짜 (리마인더 알람에 사용됨)
    // 8일(오늘날짜) 가 아닌 날짜로 설정하면 제대로 리마인더 알람이 셋팅되지 않아요.
    
    // 더미데이터
    struct ReadingData {
        let date: String
        var todayReadPages: Int?
        var targetPages: Int?
        var currentPage: Int?
    }
    
    
    @State private var readingData: [ReadingData] = [
        ReadingData(date: "2024-11-01", todayReadPages: nil, targetPages: nil, currentPage: nil), // 안읽기로 한 날
        ReadingData(date: "2024-11-02", todayReadPages: 8, targetPages: 10, currentPage: 8),
        ReadingData(date: "2024-11-03", todayReadPages: 15, targetPages: 20, currentPage: 23),
        ReadingData(date: "2024-11-04", todayReadPages: 0, targetPages: 30, currentPage: 23),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-05", todayReadPages: 12, targetPages: 40, currentPage: 35),
        ReadingData(date: "2024-11-06", todayReadPages: 10, targetPages: 50, currentPage: 45),
        ReadingData(date: "2024-11-07", todayReadPages: nil, targetPages: 60, currentPage: 45),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-08", todayReadPages: nil, targetPages: 10, currentPage: 45), // 안읽기로 한 날
        ReadingData(date: "2024-11-09", todayReadPages: 14, targetPages: 70, currentPage: 59),
        ReadingData(date: "2024-11-10", todayReadPages: 7, targetPages: 80, currentPage: 66),
        ReadingData(date: "2024-11-11", todayReadPages: 13, targetPages: 90, currentPage: 79),
        ReadingData(date: "2024-11-12", todayReadPages: 10, targetPages: 100, currentPage: 89),
        ReadingData(date: "2024-11-13", todayReadPages: 15, targetPages: 110, currentPage: 104),
        ReadingData(date: "2024-11-14", todayReadPages: 7, targetPages: 120, currentPage: 111),
        ReadingData(date: "2024-11-15", todayReadPages: nil, targetPages: nil, currentPage: 111), // 안읽기로 한 날
        ReadingData(date: "2024-11-16", todayReadPages: 12, targetPages: 130, currentPage: 123),
        ReadingData(date: "2024-11-17", todayReadPages: 0, targetPages: 140, currentPage: 123), // 오늘로 가정, 오늘 안읽음
        ReadingData(date: "2024-11-18", todayReadPages: nil, targetPages: 150, currentPage: nil),
        ReadingData(date: "2024-11-19", todayReadPages: nil, targetPages: 160, currentPage: nil), // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-20", todayReadPages: nil, targetPages: 170, currentPage: nil),
        ReadingData(date: "2024-11-21", todayReadPages: nil, targetPages: 180, currentPage: nil),
        ReadingData(date: "2024-11-22", todayReadPages: nil, targetPages: nil, currentPage: nil), // 안읽기로 한 날
        ReadingData(date: "2024-11-23", todayReadPages: nil, targetPages: 190, currentPage: nil),
        ReadingData(date: "2024-11-24", todayReadPages: nil, targetPages: 200, currentPage: nil),
        ReadingData(date: "2024-11-25", todayReadPages: nil, targetPages: 210, currentPage: nil),
        ReadingData(date: "2024-11-26", todayReadPages: nil, targetPages: 220, currentPage: nil),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-27", todayReadPages: nil, targetPages: 230, currentPage: nil),
        ReadingData(date: "2024-11-28", todayReadPages: nil, targetPages: 240, currentPage: nil),
        ReadingData(date: "2024-11-29", todayReadPages: nil, targetPages: nil, currentPage: nil),  // 안읽기로 한 날
        ReadingData(date: "2024-11-30", todayReadPages: nil, targetPages: 250, currentPage: nil),
        ReadingData(date: "2024-12-01", todayReadPages: nil, targetPages: 260, currentPage: nil),
        ReadingData(date: "2024-12-02", todayReadPages: nil, targetPages: 270, currentPage: nil),
        ReadingData(date: "2024-12-03", todayReadPages: nil, targetPages: 280, currentPage: nil),
        ReadingData(date: "2024-12-04", todayReadPages: nil, targetPages: 290, currentPage: nil),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-12-05", todayReadPages: nil, targetPages: 300, currentPage: nil),
        ReadingData(date: "2024-12-06", todayReadPages: nil, targetPages: nil, currentPage: nil),  // 안읽기로 한 날
        ReadingData(date: "2024-12-07", todayReadPages: nil, targetPages: 310, currentPage: nil),
        ReadingData(date: "2024-12-08", todayReadPages: nil, targetPages: 320, currentPage: 320)   // 완독일 12월 8일
    ]
    
    
    var body: some View {
        
        
        VStack {
            Text(notificationText)
                .font(.title)
            
            // 한번에 세개알람 설정하기
            Button(
                action: {
                    NotificationManager.shared.setupNotifications(readingData: readingData, todayDate: todayDate, hour: hour, minute: minute)
                },
                label: {
                    Text("알람 세개 동시설정")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8.0)
                }
            )
            
            Button(
                action: {
                    NotificationManager.shared.requestNotificationPermission()    // 알람 요청
                    NotificationManager.shared.scheduleSpecificTimeNotification(hour: hour, minute: minute)   // 특정시간 알람 셋팅
                },
                label: {
                    Text("특정 시간 알람 설정")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8.0)
                }
            )
            
            // 리마인더 알람 설정
            Button(
                action: {
                    NotificationManager.shared.requestNotificationPermission()    // 알람 요청
                    NotificationManager.shared.scheduleReminderNotification(readingData: readingData, todayDate: todayDate, hour: hour, minute: minute) // 리마인더 알람 셋팅
                },
                label: {
                    Text("리마인더 알람 설정")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8.0)
                }
            )
            
            // 일분 후 알람 설정
            Button(
                action: {
                    NotificationManager.shared.requestNotificationPermission()  // 알람 요청
                    NotificationManager.shared.scheduleOneMinuteNotification() // 1분 후 알람 셋팅
                },
                label: {
                    Text("일분 후 알람 설정")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8.0)
                }
            )
            
        }
    }
    
    
    
}

