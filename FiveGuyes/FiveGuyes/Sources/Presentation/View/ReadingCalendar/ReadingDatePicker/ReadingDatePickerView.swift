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
    
    private let displayedMonths: Int = 12
    private let calendarSpacing: CGFloat = 30
    
    let calendarCalculator: CalendarCalculator
    
    @StateObject private var toastViewModel = ToastViewModel()
    
    @ObservedObject private var calendarCellManager: CalendarCellModel
    
    // 초기화 시 adjustedToday를 CalendarCellModel에 주입
    init(adjustedToday: Date, calendarCalculator: CalendarCalculator = CalendarCalculator(), calendarCellManager: CalendarCellModel) {
        self.adjustedToday = adjustedToday
        
        self.calendarCalculator = calendarCalculator
        self._calendarCellManager = .init(wrappedValue: calendarCellManager)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: calendarSpacing) {
                ForEach(0..<displayedMonths, id: \.self) { monthOffset in
                    let month = calendarCalculator.addMonths(to: adjustedToday, by: monthOffset)
                    
                    CalendarGridView(month: month, calendarCalculator: calendarCalculator, calendarCellModel: calendarCellManager, toastViewModel: toastViewModel)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 20)
        }
        .overlay(alignment: .bottom) {
            ToastView(viewModel: toastViewModel)
                .padding(.bottom, 21)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("기본 상태") {
    ReadingDatePickerView(adjustedToday: Date(), calendarCalculator: CalendarCalculator(), calendarCellManager: CalendarCellModel(adjustedToday: Date()))
}

#Preview("기간 확정 상태") {
    let today = Date().adjustedDate()
    let calendar = Calendar.app
    let startDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
    let endDate = calendar.date(byAdding: .day, value: 10, to: today) ?? today

    return ReadingDatePickerView(
        adjustedToday: today,
        calendarCalculator: CalendarCalculator(),
        calendarCellManager: CalendarCellModel(
            adjustedToday: today,
            startDate: startDate,
            endDate: endDate,
            excludedDates: [],
            isConfirmed: true
        )
    )
}
