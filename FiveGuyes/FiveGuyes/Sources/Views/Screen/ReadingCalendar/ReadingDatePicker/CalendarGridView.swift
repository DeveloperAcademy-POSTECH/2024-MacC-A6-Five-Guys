//
//  CalendarGridView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/4/25.
//

import SwiftUI

/// 캘린더 그리드 뷰
/// - 특정 월(month)에 대한 날짜를 표시하는 그리드 형식의 뷰.
/// - 날짜 범위 선택, 시작/끝 날짜, 제외 날짜 등의 상태를 `CalendarCellModel`을 통해 관리.
struct CalendarGridView: View {
    // MARK: - Properties
    
    /// 현재 그리드가 표시할 월
    let month: Date
    
    /// 캘린더의 행 간 간격
    private let weekSpacing: CGFloat = 21
    
    /// 캘린더의 열 구성 (7열: 일~토)
    private let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    /// 캘린더 계산기를 통한 날짜 계산
    let calendarCalculator: CalendarCalculator
    
    /// 캘린더 셀의 상태와 로직을 관리하는 모델
    @ObservedObject var calendarCellModel: CalendarCellModel
    
    var body: some View {
        let daysInMonth = calendarCalculator.numberOfDays(in: month)
        
        // 첫 주의 시작 요일을 계산 (일요일을 기준으로 0부터 시작)
        let firstWeekday = calendarCalculator.firstWeekdayOfMonth(in: month) - 1
        
        // 전체 셀의 개수 (빈 칸 + 해당 월의 날짜)
        let totalCells = daysInMonth + firstWeekday
        
        VStack(spacing: 16) {
            // 월 표시
            Text(month.toYearMonthString())
                .foregroundStyle(Color.Labels.primaryBlack1)
                .fontStyle(.title3, weight: .semibold)
            
            LazyVGrid(columns: gridColumns, spacing: weekSpacing) {
                ForEach(0..<totalCells, id: \.self) { index in
                    if index < firstWeekday {
                        // 첫 주의 빈 칸
                        emptyCell()
                    } else {
                        // 해당 날짜 계산
                        let day = index - firstWeekday + 1
                        let date = calendarCalculator.dateForDay(index - firstWeekday, inMonth: month)
                        
                        // 날짜 셀 렌더링
                        calendarGridCell(day: day, date: date)
                    }
                }
            }
        }
    }
    
    // MARK: - Cell Views
    
    /// 빈 셀을 렌더링 (첫 주의 빈 칸)
    private func emptyCell() -> some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 44)
    }
    
    /// 날짜 셀을 렌더링
    /// - Parameters:
    ///   - day: 날짜 숫자 (1~31)
    ///   - date: 해당 셀에 대응하는 실제 날짜
    private func calendarGridCell(day: Int, date: Date) -> some View {
        ZStack {
            cellBackground(for: date)
            cellDayText(day: day, date: date)
        }
        .frame(height: 44)
        .onTapGesture {
            handleCellTap(for: date)
        }
    }
    
    /// 셀의 텍스트 (날짜) 렌더링
    /// - Parameters:
    ///   - day: 날짜 숫자 (1~31)
    ///   - date: 해당 날짜
    private func cellDayText(day: Int, date: Date) -> some View {
        let isPastDate = calendarCellModel.isPastDate(for: date)
        let isStartOrEndDate = calendarCellModel.isStartOrEndDate(for: date)
        
        return Text("\(day)")
            .foregroundStyle(isPastDate ? Color.Labels.quaternaryBlack4 : isStartOrEndDate ? Color.Fills.white : Color.Labels.secondaryBlack2)
            .fontStyle(isStartOrEndDate ? .title2 : .body, weight: isStartOrEndDate ? .semibold : .regular)
    }
    
    /// 셀의 배경 렌더링
    /// - Parameter date: 해당 날짜
    private func cellBackground(for date: Date) -> some View {
        HStack(spacing: 0) {
            if calendarCellModel.isStartOrEndDate(for: date) {
                ZStack {
                    if calendarCellModel.isRangeComplete() {  // 마지막 날이 채워지기 전에는 배경 없애기
                            HStack(spacing: 0) {
                                if calendarCellModel.isStartDate(for: date) { // 시작 날짜 배경
                                    Rectangle()
                                        .fill(Color.clear)
                                    Rectangle()
                                        .fill(Color.Fills.lightGreen)
                                } else { // 마지막 날짜 배경
                                Rectangle()
                                    .fill(Color.Fills.lightGreen)
                                Rectangle()
                                    .fill(Color.clear)
                            }
                        }
                    }
                    // 시작/끝 날짜 강조
                    Circle()
                        .fill(Color.Colors.green1)
                }
            } else if calendarCellModel.isBetweenSelectedDays(for: date) {
                Rectangle()
                    .fill(Color.Fills.lightGreen)
            } else {
                Rectangle()
                    .fill(Color.clear)
            }
        }
    }
    
    // MARK: - Actions

    /// 셀 탭 이벤트 처리
    /// - Parameter date: 탭한 셀의 날짜
    private func handleCellTap(for date: Date) {
        calendarCellModel.updateCellSelection(for: date)
    }
}

#Preview {
    let today = Date()
    CalendarGridView(
        month: today,
        calendarCalculator: CalendarCalculator(),
        calendarCellModel: CalendarCellModel(adjustedToday: today)
    )
}
