//
//  ReadingDatePickerView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/2/25.
//

import SwiftUI

struct ReadingDatePickerView: View {
    // 해당 날짜 기준으로 캘린더가 그려짐
    let adjustedToday: Date = Date().adjustedDate()
    
    let displayedMonths: Int = 12
    let calendarSpacing: CGFloat = 30
    
    let calendarCalculator: CalendarCalculator
    
    init(calendarCalculator: CalendarCalculator = CalendarCalculator()) {
        self.calendarCalculator = calendarCalculator
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: calendarSpacing) {
                ForEach(0..<displayedMonths, id: \.self) { monthOffset in
                    let month = calendarCalculator.addMonths(to: adjustedToday, by: monthOffset)
                    
                    CalendarGridView(month: month, calendarCalculator: calendarCalculator)
                }
            }
        }
    }
}

#Preview {
    ReadingDatePickerView(calendarCalculator: CalendarCalculator())
}
