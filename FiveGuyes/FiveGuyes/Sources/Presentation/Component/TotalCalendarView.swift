//
//  TotalCalendarView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 8/28/25.
//

import SwiftUI

struct TotalCalendarView: View {
    @State private var currentMonth: Date
    let todayDate: Date
    let currentReadingBook: FGUserBook

    init(currentReadingBook: FGUserBook) {
        self.currentReadingBook = currentReadingBook
        self.todayDate = Date().adjustedDate()
        _currentMonth = State(initialValue: self.todayDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
            
            dayLabels
                .padding(.bottom, 5)
                .padding(.horizontal, 8)
            
            calendarDays
                .padding(.bottom, 32)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color.Separators.green, lineWidth: 1)
                .foregroundStyle(Color.Backgrounds.primary)
        }
    }
    
    private var header: some View {
        HStack(spacing: 0) {
            Text(currentMonth.calendarHeaderString())
                .fontStyle(.body, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Labels.primaryBlack1)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 24) {
                Spacer()
                
                Button {
                    previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Button {
                    nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(Color.Colors.green2)
        }
    }
    
    private var dayLabels: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7),) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .fontStyle(.caption2, weight: .semibold)
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
                    .frame(width: 32, height: 18, alignment: .center)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private var calendarDays: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
            let (daysInMonth, startDayOfWeek) = getDateFromCalendar()
            let totalCells = startDayOfWeek + daysInMonth
            
            ForEach(0..<totalCells, id: \.self) { cellIndex in
                calendarDayCell(cellIndex: cellIndex, startDayOfWeek: startDayOfWeek)
            }
        }
        .padding(.horizontal, 10)
    }

    private func calendarDayCell(cellIndex: Int, startDayOfWeek: Int) -> some View {
        if cellIndex < startDayOfWeek {
            return AnyView(Text("")
                .frame(width: 47, height: 47))
        } else {
            let day = cellIndex - startDayOfWeek + 1
            
            guard let date = Calendar.app.date(from: DateComponents(
                year: getCurrentMonthAndYear().year,
                month: getCurrentMonthAndYear().month,
                day: day)
            ) else {
                return AnyView(EmptyView())
            }
            
            let dateKey = date.toYearMonthDayString()
            
            return AnyView(calendarDayContent(date: date, dateKey: dateKey, currentReadingBook: currentReadingBook))
        }
    }
    
    private func calendarDayContent(date: Date, dateKey: String, currentReadingBook: FGUserBook) -> some View {
        VStack(spacing: 0) {
            if let readingRecord = currentReadingBook.readingProgress.dailyReadingRecords[dateKey] {
                let isTodayCompletionDate = Calendar.app.isDate(todayDate, inSameDayAs: currentReadingBook.userSettings.targetEndDate)
                
                if Calendar.app.isDate(date, inSameDayAs: currentReadingBook.userSettings.targetEndDate) {
                    Image(isTodayCompletionDate ? "completionGreenFlag" : "completionFlag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("완독")
                                .fontStyle(.caption1, weight: .semibold)
                                .foregroundStyle(isTodayCompletionDate ? Color.Fills.white : Color.Colors.green2)
                                .padding(.bottom, 1)
                                .padding(.leading, 2)
                        )
                } else if Calendar.app.isDate(date, inSameDayAs: todayDate) {
                    // 오늘 날짜인 경우 - 초록색 배경에 목표 페이지 수 표시
                    TotalCalendarTextBubble(
                        text: "\(readingRecord.targetPages)",
                        textColor: Color.Fills.white,
                        backgroundColor: Color.Colors.green1
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
            }}
        .frame(width: 47, height: 47, alignment: .center)
    }
    
    // MARK: - Month Navigation
    
    private func previousMonth() {
        currentMonth = Calendar.app.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.app.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    // MARK: - Get Date
    
    private func getDateFromCalendar() -> (Int, Int) {
        let calendar = Calendar.app
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
        let components = Calendar.app.dateComponents([.year, .month], from: currentMonth)
        return (components.year ?? 2024, components.month ?? 1)
    }
}
