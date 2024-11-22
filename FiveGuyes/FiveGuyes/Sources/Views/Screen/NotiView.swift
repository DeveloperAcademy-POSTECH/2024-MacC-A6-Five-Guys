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
    
    @State private var selectedStartTime: Date = Date()
    @State private var isStartTimePickerVisible: Bool = false
    
    @State private var selectedReminderTime: Date = Date()
    @State private var isReminderTimePickerVisible: Bool = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Toggle("모든 알림 수신", isOn: $isToggleOn)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .toggleStyle(SwitchToggleStyle(tint: isToggleOn ? Color(red: 0.2, green: 0.78, blue: 0.35): Color(red: 0.47, green: 0.47, blue: 0.5).opacity(0.16)))
                
             //   Text(isToggleOn ? "독서 알림이 모두 수신돼요." : "알림이 꺼져 있습니다.")
                Text("독서 알림이 모두 수신돼요.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
            }
            .padding(16)
            .background(Color(red: 0.96, green: 0.98, blue: 0.97))
          //  .background(isToggleOn ? Color(red: 0.88, green: 0.96, blue: 0.88) : Color(red: 0.96, green: 0.98, blue: 0.97))
            .cornerRadius(16)
            .animation(.easeInOut, value: isToggleOn) // 애니메이션 추가
            ScrollView {
                VStack {
                    if isToggleOn {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("하루 독서 시작 알림")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("지정된 시간에 오늘의 독서 목표를 알릴게요.")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
                            }
                            Spacer()
                            HStack(alignment: .center, spacing: 1.5) {
                                Text(selectedStartTime, style: .time)
                                    .font(Font.custom("Pretendard Variable", size: 16))
                                    .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                            .cornerRadius(6)
                            // 탭하면 피커보이기
                            .onTapGesture {
                                withAnimation {
                                    isStartTimePickerVisible.toggle()
                                }
                            }
                        }
                        .padding(16)
                        .frame(width: 361, height: 78)
                        .cornerRadius(16)
                        // 시간 피커 (HStack 밑에 표시)
                                    if isStartTimePickerVisible {
                                        VStack {
                                            Text("시간 선택")
                                                .font(.system(size: 18, weight: .semibold))
                                                .padding(.bottom, 10)
                                            DatePicker(
                                                "시간 선택",
                                                selection: $selectedStartTime,
                                                displayedComponents: .hourAndMinute
                                            )
                                            .datePickerStyle(WheelDatePickerStyle()) // 휠 스타일 적용
                                            .labelsHidden() // 레이블 숨기기
                                        }
                                        .frame(width: 361, height: 214)
                                        .background(Color.white)
                                        .transition(.move(edge: .top).combined(with: .opacity)) // 애니메이션
                                        .animation(.easeInOut, value: isStartTimePickerVisible)
                                    }

                                    Spacer()
                        // 하루 독서 미완료 알림
                        HStack {
                            VStack(alignment: .leading) {
                                Text("하루 독서 미완료 알림")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("지정된 시간까지 독서하지 않으면 알릴게요.")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
                            }
                            Spacer()
                            HStack(alignment: .center, spacing: 1.5) {
                                Text(selectedReminderTime, style: .time)
                                    .font(Font.custom("Pretendard Variable", size: 16))
                                    .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                            .cornerRadius(6)
                            // 피커보이기
                            .onTapGesture {
                                withAnimation {
                                    isReminderTimePickerVisible.toggle() // 피커 보이기/숨기기 토글
                                }
                            }
                            
                        }
                        .padding(16)
                        .frame(width: 361, height: 78)
                        .cornerRadius(16)
                        // 시간 피커 (HStack 밑에 표시)
                                    if isReminderTimePickerVisible {
                                        VStack {
                                            Text("시간 선택")
                                                .font(.system(size: 18, weight: .semibold))
                                                .padding(.bottom, 10)
                                            DatePicker(
                                                "시간 선택",
                                                selection: $selectedReminderTime,
                                                displayedComponents: .hourAndMinute
                                            )
                                            .datePickerStyle(WheelDatePickerStyle()) // 휠 스타일 적용
                                            .labelsHidden() // 레이블 숨기기
                                        }
                                        .frame(width: 361, height: 214)
                                        .background(Color.white)
                                        .transition(.move(edge: .top).combined(with: .opacity)) // 애니메이션
                                        .animation(.easeInOut, value: isReminderTimePickerVisible)
                                    }

                                    Spacer()
                    } else {
                        Spacer()
                    }
                    
                }
            }
            
        }
        .padding()
    }
}

#Preview {
    NotiView()
}
