//
//  ReadingDatePickerView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/2/25.
//

import SwiftUI

struct ReadingDatePickerView: View {
    // 해당 날짜 기준으로 캘린더가 그려짐
    let adjustedToday: Date
    
    let displayedMonths: Int = 12
    let calendarSpacing: CGFloat = 30
    
    let calendarCalculator: CalendarCalculator
    
    @StateObject private var calendarCellManager: CalendarCellModel

    // 초기화 시 adjustedToday를 CalendarCellModel에 주입
    init(adjustedToday: Date, calendarCalculator: CalendarCalculator = CalendarCalculator(), calendarCellManager: CalendarCellModel) {
        let adjustedToday = Date().adjustedDate()
        self.adjustedToday = adjustedToday
        
        self.calendarCalculator = calendarCalculator
        self._calendarCellManager = StateObject(wrappedValue: calendarCellManager)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: calendarSpacing) {
                ForEach(0..<displayedMonths, id: \.self) { monthOffset in
                    let month = calendarCalculator.addMonths(to: adjustedToday, by: monthOffset)
                    
                    CalendarGridView(month: month, calendarCalculator: calendarCalculator, calendarCellModel: calendarCellManager)
                }
            }
        }
    }
}

#Preview {
    ReadingDatePickerView(adjustedToday: Date(), calendarCellManager: CalendarCellModel(adjustedToday: Date()))
}
