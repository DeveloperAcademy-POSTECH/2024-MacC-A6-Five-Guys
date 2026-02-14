//
//  ReadingDatePickerView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/2/25.
//

import SwiftUI

struct ReadingDatePickerView: View {
    // 해당 날짜 기준으로 캘린더가 그려짐
    let today: Date
    
    private let displayedMonths: Int = 12
    private let calendarSpacing: CGFloat = 30
    
    let calendarCalculator: CalendarCalculator
    
    @StateObject private var toastViewModel = ToastViewModel()
    
    @ObservedObject private var calendarCellManager: CalendarCellModel
    
    // 초기화 시 today를 CalendarCellModel에 주입
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
// 이 프리뷰는 "기본 상태" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("기본 상태") {
    ReadingDatePickerView(today: Date(), calendarCalculator: CalendarCalculator(), calendarCellManager: CalendarCellModel(today: Date()))
}

// 이 프리뷰는 "기간 확정 상태" 화면을 바로 열어,
// 입력 없이도 이 분기 UI가 맞는지 빠르게 확인하려고 만든 예시입니다.
#Preview("기간 확정 상태") {
    // 계산 기준이 흔들리지 않게 오늘 날짜를 먼저 고정합니다.
    // 기준이 매번 바뀌면 같은 프리뷰가 다르게 보여 디버깅이 어려워집니다.
    let today = DefaultReadingDateProvider().today()
    let calendar = Calendar.app
    // 시작 날짜를 명확히 정해 둡니다.
    // 그래야 이후 페이지 계산과 캘린더 표시가 같은 기준으로 움직입니다.
    let startDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
    // 종료 날짜를 정해 목표 기간 길이를 확정합니다.
    // 이 값이 없으면 하루 목표 계산 자체를 할 수 없습니다.
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
