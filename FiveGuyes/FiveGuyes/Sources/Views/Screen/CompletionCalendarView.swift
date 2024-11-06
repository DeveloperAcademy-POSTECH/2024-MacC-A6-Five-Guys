//
//  CompletionCalendarView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/6/24.
//

import SwiftUI

struct CompletionCalendarView: View {
    @State private var selectedStartDate: Int? // 시작 날짜 선택을 위한 변수
    @State private var selectedEndDate: Int? // 종료 날짜 선택을 위한 변수
    @State private var currentMonth: Date = Date() // 현재 월 설정
    @State private var daysInMonth: [Int] = Array(1...30) // 날짜 데이터 예시
    @State private var totalPages: Int = 270 // 총 페이지 예시
    @State private var currentDay: Int = Calendar.current.component(.day, from: Date())
    
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
            .padding(.bottom, 12)
            
            Divider()
                .padding(.bottom, 20)
            
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
                            let isCurrentDay = day == currentDay
                            
                            ZStack {
                                if isBetweenSelectedDays {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(height: 44)
                                } else if isSelectedDay {
                                    // 왼쪽 반 또는 오른쪽 반만 채우기
                                    HStack(spacing: 0) {
                                        if !isCurrentDay && day == selectedStartDate && selectedEndDate != nil { // 첫 글자
                                            Spacer()
                                            Rectangle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 28, height: 44)
                                            
                                        } else if  !isCurrentDay && day == selectedEndDate {
                                            Rectangle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 28, height: 44)
                                            Spacer()
                                        }
                                    }
                                }
                                
                                Text("\(day)")
                                    .frame(width: 44, height: 44)
                                    .background(
                                            // 선택된 날짜가 있을 때만 초록색 배경을 적용
                                        isSelectedDay || (!isSelectedDay && isCurrentDay) ? Color.green : Color.clear
                                        )
                                        .foregroundColor(
                                            // 선택된 날짜가 있을 때만 흰색 글자
                                            isSelectedDay || isCurrentDay ? .white : .secondary
                                        )
                                        .font(
                                            // 선택된 날짜가 있을 때만 볼드체와 큰 글자
                                            isSelectedDay || isCurrentDay ? .system(size: 24, weight: .semibold) : .system(size: 16)
                                        )
                                    .cornerRadius(26)
                                    .onTapGesture {
                                        if selectedStartDate == nil && selectedEndDate == nil {
                                            // 첫 번째 선택된 날짜를 시작일로 설정
                                            selectedStartDate = day
                                            selectedEndDate = nil // 종료일은 설정되지 않음
                                        } else if selectedStartDate == day {
                                            // 시작일이 눌리면 시작일 취소
                                            selectedStartDate = nil
                                            selectedEndDate = nil
                                        } else if selectedEndDate == day {
                                            // 종료일이 눌리면 종료일 취소
                                            selectedEndDate = nil
                                        } else if selectedStartDate != nil && day > selectedStartDate! {
                                            // 종료일을 설정할 때
                                            selectedEndDate = day
                                        } else if selectedStartDate != nil && selectedEndDate != nil {
                                            // 시작일보다 이전 날짜가 선택되면 시작일이 변경되고 종료일은 다시 설정됨
                                            if day < selectedStartDate! {
                                                selectedStartDate = day
                                            }
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
                Text("다음")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
