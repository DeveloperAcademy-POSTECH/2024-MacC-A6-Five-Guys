//
//  ReadingDateSettingView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/4/25.
//

import SwiftUI

struct ReadingDateSettingView: View {
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    @Environment(BookSettingPageModel.self) var pageModel: BookSettingPageModel
    
    @StateObject private var calendarCellModel: CalendarCellModel
    
    @State var totalPages = 0
    
    private var adjustedToday: Date
    private let calendarCalculator = CalendarCalculator()
    
    private var dayCount: Int {
        if let startDate = calendarCellModel.getStartDate(),
           let endDate = calendarCellModel.getEndDate() {
            let readingcalculator = ReadingDateCalculator()
            do {
                return try readingcalculator.calculateDaysBetween(startDate: startDate, endDate: endDate)
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            return 1
        }
    }
    
    private var pagesPerDay: Int {
        let readingPagesCalculator = ReadingPagesCalculator()
        do {
            return try readingPagesCalculator.calculatePagesPerDay(totalPages: totalPages, totalDays: dayCount)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    init() {
        let adjustedToday = Date().adjustedDate()
        // 오늘 날짜를 시작 날짜로 추가
        let calendarCellModel = CalendarCellModel(adjustedToday: adjustedToday, startDate: adjustedToday)
        
        self.adjustedToday = adjustedToday
        
        self._calendarCellModel = StateObject(wrappedValue: calendarCellModel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            descriptionText()
                .padding(.top, 32)
                .padding(.bottom, 26)
            
            CalendarWeekdayHeader(calendarCalculator: calendarCalculator)
                .padding(.bottom, 12)
            
            DividerLine()
            
            ReadingDatePickerView(adjustedToday: adjustedToday, calendarCalculator: calendarCalculator, calendarCellManager: calendarCellModel)
            
            DividerLine()
            
            nextButton()
        }
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.dateSelection.setTracking()
            
            let readingPagesCalculator = ReadingPagesCalculator()
            
            totalPages = readingPagesCalculator.calculatePagesBetween(
                endPage: bookSettingInputModel.targetEndPage,
                startPage: bookSettingInputModel.startPage
            )
        }
        .onAppear {
            if pageModel.currentPage == BookSettingsPage.bookNoneReadingDaySetting.rawValue {
                calendarCellModel.setStartDate(bookSettingInputModel.startDate)
                calendarCellModel.setEndDate(bookSettingInputModel.endDate)
                calendarCellModel.setExcludedDates(bookSettingInputModel.nonReadingDays)

                confirmReadingPeriod()
            }
        }
        .onChange(of: pageModel.currentPage) {
            if pageModel.currentPage == BookSettingsPage.bookDurationSetting.rawValue {
                resetNonReadingDays()
            }
        }
    }
    
    private func descriptionText() -> some View {
        Group {
            if !calendarCellModel.getConfirmed() {
                goalSelectionText()
            } else {
                restDaySelectionText()
            }
        }
        .fontStyle(.title2, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
        .padding(.horizontal, 20)
    }
    
    private func nextButton() -> some View {
        Button(action: nextButtonAction) {
            RoundedRectangle(cornerRadius: 16)
                .fill(calendarCellModel.isRangeComplete() ? Color.Colors.green1 : Color.Fills.lightGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay {
                    Text(calendarCellModel.getConfirmed() ? "완료" : "\(dayCount)일 동안 목표하기")
                        .foregroundStyle(Color.Fills.white)
                        .fontStyle(.title2, weight: .semibold)
                }
        }
        .padding(.top, 14)
        .padding(.bottom, 21)
        .padding(.horizontal, 16)
        .disabled(!calendarCellModel.isRangeComplete())
    }
    
    private func goalSelectionText() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("목표기간을 선택해주세요")
            
            HStack(spacing: 8) {
                Text("매일")
                
                Text("\(pagesPerDay)")
                    .pageTextStyle()
                
                Text("쪽만 읽으면 돼요")
            }
        }
    }
    
    private func restDaySelectionText() -> some View {
        HStack(alignment: .top) {
            Text("쉬는 날을 선택할 수 있어요!\n원하지 않는다면 넘어가도 좋아요")
            Spacer()
        }
    }
    
    private func nextButtonAction() {
        if !calendarCellModel.getConfirmed() {
            confirmReadingPeriod()
        } else {
            saveReadingData()
        }
        pageModel.nextPage()
    }
    
    private func confirmReadingPeriod() {
        withAnimation(.easeOut) {
            calendarCellModel.confirmDates()
        }
    }
    
    private func resetNonReadingDays() {
        withAnimation(.easeOut) {
            calendarCellModel.resetConfirmedDates()
        }
    }
    
    private func saveReadingData() {
        bookSettingInputModel.setReadingPeriod(
            startDate: calendarCellModel.getStartDate(),
            endDate: calendarCellModel.getEndDate()
        )
        bookSettingInputModel.setNonReadingDays(calendarCellModel.getExcludedDates())
    }
}

#Preview {
    ReadingDateSettingView()
}
