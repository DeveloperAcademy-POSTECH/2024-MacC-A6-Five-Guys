//
//  WeeklyPageCalendarView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

struct WeeklyPageCalendarView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    let currentReadingBook: UserBook
    
    let today = Date()
    
    // TODO: 특정 날짜 이전 요일들의 UI 수정
    var body: some View {
        let weeklyRecords = currentReadingBook.readingProgress.getAdjustedWeeklyRecorded(from: today)
        let todayIndex = Calendar.current.getAdjustedWeekdayIndex(from: today)
        
        HStack(spacing: 0) { // 셀 간격을 없앰으로써 연결된 배경처럼 보이게 설정
            ForEach(0..<daysOfWeek.count, id: \.self) { index in
                VStack(spacing: 5) {
                    Text(daysOfWeek[index]) // 요일 표시
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                    
                    ZStack {
                        // MARK: 뒷 배경 관련 코드
                        if todayIndex != 0 { // 일요일인경우 뒷 배경 필요 없음
                            if index <= todayIndex {
                                if index == 0 {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(.white)
                                            .frame(height: 44)
                                        
                                        Rectangle()
                                            .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                            .frame(height: 44)
                                    }
                                    
                                    Circle()
                                        .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                        .frame(height: 44)
                                    
                                } else if index == todayIndex {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                            .frame(height: 44)
                                            .shadow(radius: 0)
                                        
                                        Rectangle()
                                            .fill(.white)
                                            .frame(height: 44)
                                            .shadow(radius: 0)
                                    }
                                    
                                } else {
                                    Rectangle()
                                        .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                        .frame(height: 44)
                                }
                            }
                        }
                        
                        // MARK: 페이지 분량 관련 코드
                        if let record = weeklyRecords[index] { // 페이지 할당이 되어있다면
                            let hasCompletedToday = record.pagesRead == record.targetPages
                            
                            if index < todayIndex {
                                    Text(hasCompletedToday ? "\(record.pagesRead)" : "•")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                        .frame(height: 44)
                            } else if index == todayIndex { // today
                                    Circle()
                                        .fill(hasCompletedToday ?
                                              Color(red: 0.07, green: 0.87, blue: 0.54) :
                                                Color(red: 0.84, green: 0.97, blue: 0.88)
                                        )
                                        .frame(height: 44)
                                    
                                    Text("\(record.targetPages)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(height: 44)
                            } else {
                                Text("\(record.targetPages)")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                                    .frame(height: 44)
                            }
                        } else { // 페이지 할당이 없다면
                            if index == todayIndex { // today
                                Circle()
                                    .fill(Color(red: 0.07, green: 0.87, blue: 0.54))
                                    .frame(height: 44)
                            }
                            Text("")
                                .frame(height: 44)
                                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
