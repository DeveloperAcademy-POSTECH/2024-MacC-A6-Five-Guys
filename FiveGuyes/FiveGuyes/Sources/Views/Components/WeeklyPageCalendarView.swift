//
//  WeeklyPageCalendarView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

struct WeeklyPageCalendarView: View {
    // 요일과 페이지 수를 저장하는 배열 (임의로 페이지 수 지정)
    let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    let pageCounts = [10, 20, 15, 25, 30, 18, 22] // 각 요일에 해당하는 페이지 수
    
    // 특정 날짜를 선택하는 인덱스
    var selectedDayIndex: Int = 3
    
    // TODO: 특정 날짜 이전 요일들의 UI 수정
    var body: some View {
        ZStack {
            // Grid를 이용해 일주일 요일과 페이지 수를 표시
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                ForEach(0..<daysOfWeek.count, id: \.self) { index in
                    VStack(spacing: 5) {
                        Text(daysOfWeek[index]) // 요일 표시
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black)
                        
                        ZStack {
                            if index == selectedDayIndex {
                                // 선택된 날짜에 대해 원형 배경 추가
                                Circle()
                                    .fill(Color(red: 0.07, green: 0.87, blue: 0.54))
                                    .frame(height: 44)
                            }
                            
                            Text("\(pageCounts[index])") // 페이지 수 표시
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(index == selectedDayIndex ? .white : .black)
                                .frame(height: 44)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    WeeklyPageCalendarView()
}
