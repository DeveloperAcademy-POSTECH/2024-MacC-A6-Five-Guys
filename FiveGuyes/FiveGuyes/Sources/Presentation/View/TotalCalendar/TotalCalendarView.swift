//
//  TotalCalendarView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/6/24.
//

import SwiftUI

struct TotalCalendarView: View {
    // 현재 보고 있는 달력의 월 ⏰
    @State private var currentMonth = Date().adjustedDate()
    private let todayDate = Date().adjustedDate()
    
    let currentReadingBook: FGUserBook
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 27)
                .padding(.bottom, 29)
            
            dayLabels
                .padding(.bottom, 22)
            
            calendarDays
                .padding(.bottom, 43)
            
            Divider()
                .padding(.bottom, 8)
            
            CompletionFooter
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationTitle("전체 독서 현황")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.calendarView.setTracking()
        }
    }
    
    private var header: some View {
        ZStack {
            Text(calendarHeaderString(for: currentMonth))
                .fontStyle(.body, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Labels.primaryBlack1)
            
            HStack(alignment: .center, spacing: 28) {
                Spacer()
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
                .padding(.trailing, 20)
            }
            .foregroundStyle(Color.Labels.primaryBlack1)
        }
        
    }
    
    private var dayLabels: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .fontStyle(.caption1, weight: .semibold) // TODO: 디자이너 확인중
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
                    .frame(width: 32, height: 18, alignment: .center)
                    .padding(.horizontal, 16)
            }
        }
        
    }
    
    private var calendarDays: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            let (daysInMonth, startDayOfWeek) = getDateFromCalendar()
            let totalCells = startDayOfWeek + daysInMonth
            
            ForEach(0..<totalCells, id: \.self) { index in
                if index < startDayOfWeek {
                    Text("")
                        .frame(width: 50, height: 50)
                } else {
                    let day = index - startDayOfWeek + 1
                    let date = Calendar.current.date(from: DateComponents(year: getCurrentMonthAndYear().year, month: getCurrentMonthAndYear().month, day: day))!
                    let dateKey = date.toYearMonthDayString()
                    
                    VStack(spacing: 0) {
                        if let readingRecord = currentReadingBook.readingProgress.dailyReadingRecords[dateKey] {
                            
                            let isTodayCompletionDate = Calendar.current.isDate(todayDate, inSameDayAs: currentReadingBook.userSettings.targetEndDate)
                            
                            if Calendar.current.isDate(date, inSameDayAs: currentReadingBook.userSettings.targetEndDate) {
                                Image(isTodayCompletionDate ? "completionGreenFlag" : "completionFlag")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("완독")
                                            .fontStyle(.caption1, weight: .semibold)
                                            .foregroundStyle(isTodayCompletionDate ? Color.Fills.white : Color.Colors.green2)
                                            .padding(.bottom, 1)
                                            .padding(.leading, 2)
                                    )
                            } else if Calendar.current.isDate(date, inSameDayAs: todayDate) {
                                // 오늘 날짜인 경우 - 초록색 배경에 목표 페이지 수 표시
                                TotalCalendarTextBubble(
                                    text: "\(readingRecord.targetPages)",
                                    textColor: Color.Fills.white,
                                    backgroundColor: Color.Colors.green1,
                                    fontWeight: .semibold
                                )
                            } else if readingRecord.pagesRead == readingRecord.targetPages {
                                // 목표 페이지를 달성한 날 - 녹색 배경의 읽은 페이지 수 표시
                                TotalCalendarTextBubble(
                                    text: "\(readingRecord.pagesRead)",
                                    textColor: Color.Labels.secondaryBlack2,
                                    backgroundColor: Color.Colors.green
                                )
                            } else if date > todayDate {
                                // 미래의 날짜로 계획이 설정된 날 - 회색 텍스트로 목표 페이지 수 표시
                                TotalCalendarTextBubble(
                                    text: "\(readingRecord.targetPages)",
                                    textColor: Color.Labels.quaternaryBlack4,
                                    backgroundColor: .clear
                                )
                            } else {
                                // 과거 날짜에서 계획은 설정되었지만, 읽지 않은 날 - 회색 점으로 결석 표시
                                TotalCalendarTextBubble(
                                    text: "•",
                                    textColor: Color.Labels.secondaryBlack2,
                                    backgroundColor: Color.Fills.lightGreen
                                )
                            }
                        } else {
                            // 계획되지 않은 날 - 빈 배경
                            TotalCalendarTextBubble(
                                text: "",
                                textColor: Color.clear,
                                backgroundColor: Color.Fills.lightGreen
                            )
                        }
                    }
                    .frame(width: 50, height: 50, alignment: .center)
                }
            }
        }
    }
    
    private var CompletionFooter: some View {
        HStack(alignment: .center) {
            Text("완독 종료일")
                .fontStyle(.body, weight: .semibold)
            
            Spacer()
            
            Text("\(formattedCompletionDateString(from: currentReadingBook.userSettings.targetEndDate))")
                .fontStyle(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Colors.green2)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Color.Fills.lightGreen)
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .frame(width: 361, alignment: .center)
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func calendarHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    
    private func getDateFromCalendar() -> (Int, Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfCurrentMonth = calendar.date(from: components),
              let rangeOfMonth = calendar.range(of: .day, in: .month, for: firstDayOfCurrentMonth) else {
            return (0, 0)
        }
        
        let numberOfDaysInMonth = rangeOfMonth.count
        let startDayOfWeek = calendar.component(.weekday, from: firstDayOfCurrentMonth) - 1
        return (numberOfDaysInMonth, startDayOfWeek)
    }
    
    private func getCurrentMonthAndYear() -> (year: Int, month: Int) {
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        return (components.year ?? 2024, components.month ?? 1)
    }
    
    private func formattedCompletionDateString(from date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M월 d일 EEEE"
        return displayFormatter.string(from: date)
    }
}
