//
//  ReadingDatePickerView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/2/25.
//

import SwiftUI

struct ReadingDatePickerView: View {
    let today: Date

    private let displayedMonths: Int = 12
    private let calendarSpacing: CGFloat = 30

    let calendarCalculator: CalendarCalculator

    @StateObject private var toastViewModel = ToastViewModel()

    @ObservedObject private var calendarCellManager: CalendarCellModel

    init(today: Date, calendarCalculator: CalendarCalculator = CalendarCalculator(), calendarCellManager: CalendarCellModel) {
        self.today = today

        self.calendarCalculator = calendarCalculator
        self._calendarCellManager = .init(wrappedValue: calendarCellManager)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: calendarSpacing) {
                ForEach(0..<displayedMonths, id: \.self) { monthOffset in
                    let month = calendarCalculator.addMonths(to: today, by: monthOffset)

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

#if DEBUG
#Preview("기본 상태") {
    ReadingDatePickerView(today: Date(), calendarCalculator: CalendarCalculator(), calendarCellManager: CalendarCellModel(today: Date()))
}

#Preview("기간 확정 상태") {
    let today = DefaultReadingDateProvider().today()
    let calendar = Calendar.app
    let startDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
    let endDate = calendar.date(byAdding: .day, value: 10, to: today) ?? today

    ReadingDatePickerView(
        today: today,
        calendarCalculator: CalendarCalculator(),
        calendarCellManager: CalendarCellModel(
            today: today,
            startDate: startDate,
            endDate: endDate,
            excludedDates: [],
            isConfirmed: true
        )
    )
}
#endif
