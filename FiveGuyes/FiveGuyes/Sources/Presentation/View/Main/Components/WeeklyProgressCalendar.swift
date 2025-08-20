//
//  WeeklyProgressCalendar.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

struct WeeklyProgressCalendar: View {
    @State private var allWeekStartDates: [Date] = []
    @State private var currentWeekPageIndex: Int = 0
    
    @State private var lastWeekIndex = 0
    @State private var lastDayIndex = 0
    
    let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    
    var userBook: FGUserBook
    let today: Date
    
    private var todayIndex: Int {
        Calendar.current.getAdjustedWeekdayIndex(from: today)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: .zero) {
                    ForEach(Array(allWeekStartDates.enumerated()), id: \.offset) { weekPageIndex, weekStartDate in
                        
                        let weeklyRecords = userBook.readingProgress.getAdjustedWeeklyRecorded(from: weekStartDate)
                        
                        HStack(spacing: 0) { // 셀 간격을 없앰으로써 연결된 배경처럼 보이게 설정
                            ForEach(0..<daysOfWeek.count, id: \.self) { dayIndex in
                                let record = weeklyRecords[dayIndex]
                                VStack(spacing: 10) {
                                    
                                    // 요일 셀
                                    dayTextView(daysOfWeek[dayIndex])
                                    
                                    // 페이지 셀
                                    if weekPageIndex == currentWeekPageIndex { // 이번 주
                                        currentWeekView(dayIndex: dayIndex, todayIndex: todayIndex, weekPageIndex: weekPageIndex, record: record)
                                            .frame(height: 40)
                                    } else if weekPageIndex < currentWeekPageIndex { // 과거
                                        pastWeekView(dayIndex: dayIndex, record: record)
                                            .frame(height: 40)
                                        
                                    } else { // 미래
                                        futureWeekView(dayIndex: dayIndex, weekPageIndex: weekPageIndex, record: record)
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
                allWeekStartDates = userBook.userSettings.weeklyStartDates(today: today)
                
                // 오늘 날짜가 포함된 주의 인덱스를 찾음
                let todayWeekIndex = allWeekStartDates.firstIndex {
                    let calendar = Calendar.current
                    return calendar.isDate(today, equalTo: $0, toGranularity: .weekOfMonth)
                }
                
                // 현재 페이지 인덱스를 업데이트
                if let todayWeekIndex {
                    currentWeekPageIndex = todayWeekIndex
                }
                
                calculateLastWeekAndDayIndex(
                    totalWeeks: allWeekStartDates.count,
                    targetEndDate: userBook.userSettings.targetEndDate
                )
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
    
    private func currentWeekView(
        dayIndex: Int,
        todayIndex: Int,
        weekPageIndex: Int,
        record: ReadingRecord?
    ) -> some View {
        ZStack {
            // 배경 처리
            backgroundForCurrentWeek(dayIndex: dayIndex, todayIndex: todayIndex)
            
            if isLastDay(weekPageIndex: weekPageIndex, dayIndex: dayIndex) {
                // 마지막 날 이미지 표시
                completionImage
            } else {
                // 일반 텍스트 표시
                textForCurrentWeek(record, dayIndex: dayIndex, todayIndex: todayIndex)
            }
        }
    }
    
    private func futureWeekView(
        dayIndex: Int,
        weekPageIndex: Int,
        record: ReadingRecord?
    ) -> some View {
        ZStack {
            backgroundForFutureWeek()
            
            if isLastDay(weekPageIndex: weekPageIndex, dayIndex: dayIndex) {
                // 마지막 날 이미지 표시
                completionImage
            } else {
                // 일반 텍스트 표시
                futureWeekText(record: record)
            }
        }
    }
    
    private var completionImage: some View {
        Image("completionGreenFlag")
            .resizable()
            .scaledToFit()
            .overlay(
                Text("완독")
                    .fontStyle(.caption1, weight: .semibold)
                    .foregroundStyle(Color.Fills.white)
                    .padding(.bottom, 1)
                    .padding(.leading, 2)
            )
    }
    
    // MARK: - Background Handlers
    private func backgroundForPastWeek(dayIndex: Int) -> some View {
        Group {
            if dayIndex == 0 { // 일요일
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.Fills.white)
                        Rectangle().fill(Color.Fills.lightGreen)
                    }
                    Circle().fill(Color.Fills.lightGreen)
                }
            } else if dayIndex == 6 { // 토요일
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.Fills.lightGreen)
                        Rectangle().fill(Color.Fills.white)
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
                    Rectangle().fill(Color.Fills.white)
                }
            } else if dayIndex == 0 {
                ZStack {
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.Fills.white)
                        Rectangle().fill(Color.Fills.lightGreen)
                    }
                    Circle().fill(Color.Fills.lightGreen)
                }
            } else if dayIndex < todayIndex {
                Rectangle().fill(Color.Fills.lightGreen)
            } else {
                Rectangle().fill(Color.Fills.white) // 기본 배경
            }
        }
    }
    
    private func backgroundForFutureWeek() -> some View {
        Rectangle().fill(Color.Fills.white) // 미래 상태의 기본 배경
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
                            .foregroundStyle(Color.Fills.white)
                    }
                } else {
                    Text("\(record.targetPages)")
                        .fontStyle(.title3)
                        .foregroundStyle(Color.Labels.secondaryBlack2)
                }
            } else {
                    if dayIndex == todayIndex {
                        Circle().fill(Color.Separators.green)
                }
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
    
    // MARK: - Method
    /// 마지막 독서일의 주 인덱스와 요일 인덱스를 계산하여 저장합니다.
    /// - Parameters:
    ///   - totalWeeks: 전체 주의 개수.
    ///   - targetEndDate: 목표 종료 날짜.
    private func calculateLastWeekAndDayIndex(totalWeeks: Int, targetEndDate: Date) {
        lastWeekIndex = totalWeeks - 1
        // 목표 종료 날짜의 요일 인덱스 계산
        lastDayIndex = Calendar.current.getWeekdayIndex(from: targetEndDate)
    }
    
    /// 특정 주와 요일 인덱스가 마지막 독서일과 일치하는지 확인합니다.
    /// - Parameters:
    ///   - weekPageIndex: 현재 주의 페이지 인덱스.
    ///   - dayIndex: 현재 요일의 인덱스.
    /// - Returns: 주와 요일 인덱스가 마지막 독서일과 동일하면 `true`, 그렇지 않으면 `false`.
    private func isLastDay(weekPageIndex: Int, dayIndex: Int) -> Bool {
        return weekPageIndex == lastWeekIndex && dayIndex == lastDayIndex
    }
}
