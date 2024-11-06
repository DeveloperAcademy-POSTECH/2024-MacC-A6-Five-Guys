//
//  CompletionCalendarView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/6/24.
//

import SwiftUI

struct CompletionCalendarView: View {
    @State private var selectedStartDate: Int? = 1 // 시작 날짜 선택을 위한 변수
    @State private var selectedEndDate: Int? = 30 // 종료 날짜 선택을 위한 변수
    @State private var currentMonth: Date = Date() // 현재 월 설정
    @State private var daysInMonth: [Int] = Array(1...30) // 날짜 데이터 예시
    @State private var totalPages: Int = 270 // 총 페이지 예시
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 M월"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 10)
            
            Divider()
                .padding(.bottom, 10)
            
            // 스크롤 가능 영역
            ScrollView {
                VStack {
                    Text(monthFormatter.string(from: currentMonth))
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.bottom, 10)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 16) {
                        ForEach(daysInMonth, id: \.self) { day in
                            let isSelectedDay = day == selectedStartDate || day == selectedEndDate
                            let isBetweenSelectedDays = selectedStartDate != nil && selectedEndDate != nil &&
                            day > selectedStartDate! && day < selectedEndDate!
                            
                            ZStack {
                                if isBetweenSelectedDays {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(height: 44)
                                } else if isSelectedDay {
                                    // 왼쪽 반 또는 오른쪽 반만 채우기
                                    HStack(spacing: 0) {
                                        if day == selectedStartDate {
                                            Spacer()
                                            Rectangle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 28, height: 44)
                                                
                                        } else if day == selectedEndDate {
                                            Rectangle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 28, height: 44)
                                            Spacer()
                                        }
                                    }
                                }
                                
                                Text("\(day)")
                                    .frame(width: 44, height: 44)
                                    .background(isSelectedDay ? Color.green : Color.clear)
                                    .foregroundColor(isSelectedDay ? .white : .secondary)
                                    .font(isSelectedDay ? .system(size: 24, weight: .semibold) : .system(size: 16))
                                    .cornerRadius(26)
                                    .onTapGesture {
                                        if selectedStartDate == nil || day < selectedStartDate! {
                                            selectedStartDate = day
                                        } else {
                                            selectedEndDate = day
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.top, 6)
            }
            .frame(maxHeight: 400) // 스크롤 가능한 높이 지정
            Divider()
                .padding(.bottom, 14)
            Button {
                // TODO: 쉬는 날 소거 캘린더로 가기
            } label: {
//                Text("\(selectedEndDate! - selectedStartDate! + 1)일 목표하기")
                Text("다음으로 가기")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 361, height: 56)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
        }
    }
}

#Preview {
    CompletionCalendarView()
}
