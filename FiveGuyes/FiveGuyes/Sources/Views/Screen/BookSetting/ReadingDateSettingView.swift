//
//  ReadingDateSettingView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/4/25.
//

import SwiftUI

struct ReadingDateSettingView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @StateObject private var calendarCellManager: CalendarCellModel
    
    @State var totalPages = 0
    
    private var adjustedToday: Date
    private let calendarCalculator = CalendarCalculator()
    
    private var dayCount: Int {
        if let startDate = calendarCellManager.getStartDate(),
           let endDate = calendarCellManager.getEndDate() {
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
        self._calendarCellManager = StateObject(wrappedValue: calendarCellModel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            descriptionText()
                .padding(.top, 32)
                .padding(.bottom, 26)
            
            weekdayHeader()
                .padding(.bottom, 12)
            
            dividerLine()
            
            ReadingDatePickerView(adjustedToday: adjustedToday, calendarCalculator: calendarCalculator, calendarCellManager: calendarCellManager)
            
            dividerLine()
            
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
        
    }
    
    private func descriptionText() -> some View {
        Group {
            if !calendarCellManager.getConfirmed() {
                goalSelectionText()
            } else {
                restDaySelectionText()
            }
        }
        .fontStyle(.title2, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
        .padding(.horizontal, 20)
    }
    
    private func weekdayHeader() -> some View {
        HStack(spacing: 20) {
            ForEach(calendarCalculator.getWeekdayHeaders(), id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .fontStyle(.caption1, weight: .semibold)
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
            }
        }
        .padding(.horizontal, 23)
    }
    
    private func dividerLine() -> some View {
        Rectangle()
            .fill(Color.Separators.gray)
            .frame(height: 1)
    }
    
    private func nextButton() -> some View {
        Button(action: nextButtonAction) {
            RoundedRectangle(cornerRadius: 16)
                .fill(calendarCellManager.isRangeComplete() ? Color.Colors.green1 : Color.Fills.lightGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay {
                    Text(calendarCellManager.getConfirmed() ? "완료" : "\(dayCount)일 동안 목표하기")
                        .foregroundStyle(Color.Fills.white)
                        .fontStyle(.title2, weight: .semibold)
                }
            
        }
        .padding(.top, 14)
        .padding(.bottom, 21)
        .padding(.horizontal, 16)
        .disabled(!calendarCellManager.isRangeComplete())
    }
    
    private func goalSelectionText() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("목표기간을 선택해주세요")
            
            HStack(spacing: 8) {
                Text("매일")
                
                Text("\(pagesPerDay)")
                    .fontStyle(.title2, weight: .semibold)
                    .foregroundStyle(Color.Colors.green2)
                    .padding(.horizontal, 8) // 텍스트 필드와 이미지 주변 패딩
                    .padding(.vertical, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(Color.Fills.lightGreen)
                    }
                
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
        if !calendarCellManager.getConfirmed() {
            withAnimation(.easeOut) {
                calendarCellManager.confirmDates()
            }
        } else {
            // 입력 데이터 추가
            bookSettingInputModel.startData = calendarCellManager.getStartDate()
            bookSettingInputModel.endData = calendarCellManager.getEndDate()
            bookSettingInputModel.nonReadingDays = calendarCellManager.getExcludedDates()
            
            // 페이지 이동
            bookSettingInputModel.nextPage()
        }
    }
}

#Preview {
    ReadingDateSettingView()
}
