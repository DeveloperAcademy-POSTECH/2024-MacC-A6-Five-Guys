//
//  ReadingDateEditView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/4/25.
//

import SwiftUI

struct ReadingDateEditView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    private let userBook: UserBook
    
    @StateObject private var calendarCellModel: CalendarCellModel
    
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
        let userSettings = userBook.userSettings
        
        let totalPages = readingPagesCalculator.calculatePagesBetween(
            endPage: userSettings.targetEndPage,
            startPage: userSettings.startPage
        )
        
        do {
            return try readingPagesCalculator.calculatePagesPerDay(totalPages: totalPages, totalDays: dayCount)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    init(userBook: UserBook) {
        self.adjustedToday = Date().adjustedDate()
        self.userBook = userBook
        
        let userSettings = userBook.userSettings
        
        let calendarCellModel = CalendarCellModel(
            adjustedToday: adjustedToday,
            startDate: userSettings.startDate,
            endDate: userSettings.targetEndDate,
            excludedDates: userSettings.nonReadingDays,
            isConfirmed: false)
        
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
        .navigationTitle("목표기간 수정하기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
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
        Button {
            if !calendarCellModel.getConfirmed() {
                withAnimation(.easeOut) {
                    calendarCellModel.confirmDates()
                }
            } else {
                // 페이지 재할당 로직 호출
                reassignPages()
                // 페이지 나가기
                navigationCoordinator.popToRoot()
            }
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(calendarCellModel.isRangeComplete() ? Color.Colors.green1 : Color.Fills.lightGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay {
                    Text(calendarCellModel.getConfirmed() ? "\(dayCount)일 동안 목표하기" : "다음")
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
        let title = userBook.bookMetaData.title
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("<\(title)")
                    
                Text(">\(title.subjectParticle())")
                
                Text("\(userBook.userSettings.targetEndPage)")
                    .pageTextStyle()
                    .padding(.horizontal, 8)
                
                Text("쪽까지예요")
            }
            .lineLimit(1)
            
            HStack(spacing: 8) {
                Text("매일")
                
                Text("\(pagesPerDay)")
                    .pageTextStyle()
                
                Text("쪽만 읽으면 돼요")
            }
        }
    }
    
    private func reassignPages() {
        let userSetting = userBook.userSettings
        guard let startDate = calendarCellModel.getStartDate(), let endDate = calendarCellModel.getEndDate() else { return }
        
        userSetting.startDate = startDate
        userSetting.targetEndDate = endDate
        userSetting.nonReadingDays = calendarCellModel.getExcludedDates()
        
        let readingScheduleCalculator = ReadingScheduleCalculator()
        
        readingScheduleCalculator.reassignPagesForUpdatedDates(
            settings: userSetting,
            progress: userBook.readingProgress
        )
    }
    
    private func restDaySelectionText() -> some View {
        HStack(alignment: .top) {
            Text("쉬는 날을 다시 설정할 수 있어요!\n건너뛰어도 괜찮아요")
            Spacer()
        }
    }
}
