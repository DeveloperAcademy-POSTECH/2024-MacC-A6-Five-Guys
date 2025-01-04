//
//  CalendarGridView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/4/25.
//

import SwiftUI

struct CalendarGridView: View {
    var month: Date
    let calendarCalculator: CalendarCalculator
    
    private let weekSpacing: CGFloat = 21
    
    private let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        let daysInMonth = calendarCalculator.numberOfDays(in: month)
        
        // 일요일을 0으로 맞추기 위해 -1
        let firstWeekday = calendarCalculator.firstWeekdayOfMonth(in: month) - 1
        
        let totalCells = daysInMonth + firstWeekday
        
        VStack(spacing: 16) {
            Text(month.toYearMonthString())
                .foregroundStyle(Color.Labels.primaryBlack1)
                .fontStyle(.title3, weight: .semibold)
            
            LazyVGrid(columns: gridColumns, spacing: weekSpacing) {
                ForEach(0..<totalCells, id: \.self) { index in
                    if index < firstWeekday {
                        // 첫 주의 빈 칸을 채우기 위한 공간
                        emptyCell()
                        
                    } else {
                        // 며칠인지 구하기
                        let day = index - firstWeekday + 1
                        
                        // 셀에 해당하는 실제 Date 값 (이후에 해당 셀에 넣어줘야 함.)
                        let date = calendarCalculator.dateForDay(index - firstWeekday, inMonth: month)
                        
                        // 날짜 셀
                        calendarGridCell(day: day, date: date)
                    }
                }
            }
        }
    }
    
    private func emptyCell() -> some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 44)
    }
    
    private func calendarGridCell(day: Int, date: Date) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 44)
            .overlay {
                Text("\(day)")
                    .foregroundStyle(Color.Labels.secondaryBlack2)
                    .fontStyle(.body)
            }
    }
}

#Preview {
    CalendarGridView(month: Date(), calendarCalculator: CalendarCalculator())
}
