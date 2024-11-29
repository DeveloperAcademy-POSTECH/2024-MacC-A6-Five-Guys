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
    
    @State private var allWeekStartDates: [Date] = []
    @State private var currentWeekPageIndex: Int = 0
    
    var body: some View {
        let todayIndex = Calendar.current.getAdjustedWeekdayIndex(from: today)
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: .zero) {
                    ForEach(Array(allWeekStartDates.enumerated()), id: \.offset) { weekPageIndex, weekStartDate in
                        
                        let weeklyRecords = currentReadingBook.readingProgress.getAdjustedWeeklyRecorded(from: weekStartDate)
                        
                        HStack(spacing: 0) { // 셀 간격을 없앰으로써 연결된 배경처럼 보이게 설정
                            ForEach(0..<daysOfWeek.count, id: \.self) { dayIndex in
                                VStack(spacing: 10) {
                                    
                                    // 요일 셀
                                    dayTextView(daysOfWeek[dayIndex])
                                    
                                    // 페이지 셀
                                    if weekPageIndex == currentWeekPageIndex { // 이번 주
                                        currentWeekView(dayIndex: dayIndex, todayIndex: todayIndex, record: weeklyRecords[dayIndex])
                                            .frame(height: 40)
                                    } else if weekPageIndex < currentWeekPageIndex { // 과거
                                        pastWeekView(dayIndex: dayIndex, record: weeklyRecords[dayIndex])
                                            .frame(height: 40)
                                        
                                    } else { // 미래
                                        futureWeekView(record: weeklyRecords[dayIndex])
                                            .frame(height: 40)
                                        
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .id(weekPageIndex)
                        .containerRelativeFrame(.horizontal, count: allWeekStartDates.count, span: allWeekStartDates.count, spacing: 0)
                        .scrollTargetLayout()
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .onAppear {
                // 모든 주 시작 날짜를 가져옴
                allWeekStartDates = currentReadingBook.readingProgress.getAllWeekStartDates(for: currentReadingBook.userSettings)
                
                // 오늘 날짜가 포함된 주의 인덱스를 찾음
                let todayWeekIndex = allWeekStartDates.firstIndex {
                    let calendar = Calendar.current
                    return calendar.isDate(today, equalTo: $0, toGranularity: .weekOfMonth)
                }
                
                // 현재 페이지 인덱스를 업데이트
                if let todayWeekIndex {
                    currentWeekPageIndex = todayWeekIndex
                }
                
            // TODO: 마지막 날의 페이지 인덱스와 요일 인덱스 찾기
            }
            .onChange(of: currentWeekPageIndex) {
                DispatchQueue.main.async {
                    // 현재 페이지에 해당하는 위치로 스크롤
                    proxy.scrollTo(currentWeekPageIndex, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Views
    private func dayTextView(_ text: String) -> some View {
        Text(text) // 요일 표시
            .fontStyle(.caption1)
            .foregroundStyle(Color.Labels.tertiaryBlack3)
            .frame(height: 18)
    }
    
    private func pastWeekView(dayIndex: Int, record: ReadingRecord?) -> some View {
        ZStack {
            backgroundForPastWeek(dayIndex: dayIndex)
            pastWeekText(record: record)
        }
    }
    
    private func currentWeekView(dayIndex: Int, todayIndex: Int, record: ReadingRecord?) -> some View {
        ZStack {
            // 배경 처리
            backgroundForCurrentWeek(dayIndex: dayIndex, todayIndex: todayIndex)
            // 텍스트
            if let record {
                textForCurrentWeek(record, dayIndex: dayIndex, todayIndex: todayIndex)
            }
        }
    }
    
    private func futureWeekView(record: ReadingRecord?) -> some View {
        ZStack {
            backgroundForFutureWeek()
            futureWeekText(record: record)
        }
    }

    // MARK: - Background Handlers
    private func backgroundForPastWeek(dayIndex: Int) -> some View {
        Group {
            if dayIndex == 0 { // 일요일
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle().fill(.white)
                        Rectangle().fill(Color.Fills.lightGreen)
                    }
                    Circle().fill(Color.Fills.lightGreen)
                }
            } else if dayIndex == 6 { // 토요일
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.Fills.lightGreen)
                        Rectangle().fill(.white)
                    }
                    Circle().fill(Color.Fills.lightGreen)
                }
            } else {
                Rectangle().fill(Color.Fills.lightGreen)
            }
        }
    }
    
    private func backgroundForCurrentWeek(dayIndex: Int, todayIndex: Int) -> some View {
        Group {
            if dayIndex == todayIndex {
                HStack(spacing: 0) {
                    Rectangle().fill(Color.Fills.lightGreen)
                    Rectangle().fill(.white)
                }
            } else if dayIndex == 0 {
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle().fill(.white)
                        Rectangle().fill(Color.Fills.lightGreen)
                    }
                    Circle().fill(Color.Fills.lightGreen)
                }
            } else if dayIndex < todayIndex {
                Rectangle().fill(Color.Fills.lightGreen)
            } else {
                Rectangle().fill(.white) // 기본 배경
            }
        }
    }
    
    private func backgroundForFutureWeek() -> some View {
        Rectangle().fill(.white) // 미래 상태의 기본 배경
    }
    
    // MARK: - Text Handlers
    private func pastWeekText(record: ReadingRecord?) -> some View {
        Group {
            if let record {
                let hasCompletedToday = record.pagesRead == record.targetPages
                Text(hasCompletedToday ? "\(record.pagesRead)" : "•")
                    .fontStyle(.title3)
                    .foregroundStyle(Color.Labels.quaternaryBlack4)
            } else {
                Text("")
            }
        }
    }
    
    private func textForCurrentWeek(_ record: ReadingRecord?, dayIndex: Int, todayIndex: Int) -> some View {
        Group {
            if let record {
                let hasCompletedToday = record.pagesRead == record.targetPages
                
                if dayIndex < todayIndex {
                    Text(hasCompletedToday ? "\(record.pagesRead)" : "•")
                        .fontStyle(.title3)
                        .foregroundStyle(Color.Labels.quaternaryBlack4)
                } else if dayIndex == todayIndex {
                    ZStack {
                        Circle().fill(hasCompletedToday ? Color.Colors.green1 : Color.Separators.green)
                        
                        Text("\(record.targetPages)")
                            .fontStyle(.title3, weight: .semibold)
                            .foregroundStyle(.white)
                    }
                } else {
                    Text("\(record.targetPages)")
                        .fontStyle(.title3)
                        .foregroundStyle(Color.Labels.secondaryBlack2)
                }
            } else {
                Text("")
            }
        }
    }
    
    private func futureWeekText(record: ReadingRecord?) -> some View {
        Group {
            if let record {
                Text("\(record.targetPages)")
            } else {
                Text("")
            }
        }
        .fontStyle(.title3)
        .foregroundStyle(Color.Labels.secondaryBlack2)
    }
}
