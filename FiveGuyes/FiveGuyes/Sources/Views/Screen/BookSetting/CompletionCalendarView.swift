//
//  CompletionCalendarView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/6/24.
//

import SwiftUI

struct CompletionCalendarView: View {
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    // 00:00 ~ 03:59까지도 전날
    private var adjustedToday = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
    
    @State private var startDate: Date? = Calendar.current.date(byAdding: .hour, value: -4, to: Date())
    @State private var endDate: Date?
    @State private var currentMonth: Date = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
    
    @State var totalPages = 0
    
    @State private var deletedDates: [Date] = []
    @State private var isDateSelectionLocked = false
    @State private var isFirstClick = true
    
    // MARK: 추가된 변수
//    @State private var pagesPerDay = 0
//    @State private var dayCount = 0
    
    private var dayCount: Int {
        Calendar.current.getDateGap(from: startDate, to: endDate)
    }
    
    private var pagesPerDay: Int {
        get {
            if dayCount == 0 {
                return totalPages
            }
            return totalPages / dayCount
        }
    }
    
    var body: some View {
        let bookTitle = bookSettingInputModel.selectedBook?.title ?? ""

        VStack(spacing: 0) {
            
            VStack(alignment: .leading, spacing: 0) {
                if isFirstClick {
                    Text("<\(bookTitle)>\(bookTitle.subjectParticle())")
                        .lineLimit(1) // 제목이 길어지면 줄바꿈 허용
                    
                    HStack(spacing: 8) {
                        Text("총")
                        
                        Text("\(totalPages)")
                            .fontStyle(.title2, weight: .semibold)
                            .foregroundStyle(Color.Colors.green2)
                            .padding(.horizontal, 8) // 텍스트 필드와 이미지 주변 패딩
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundStyle(Color(Color.Fills.lightGreen))
                            }
                        
                        Text("쪽이에요")
                        
                        Spacer()
                    }
                    Text("목표기간을 선택해주세요")
                    
                    HStack(spacing: 8) {
                        Text("매일")
                        
                        // TODO: 페이지 할당량 계산
                        Text("\(pagesPerDay)")
                            .fontStyle(.title2, weight: .semibold)
                            .foregroundStyle(Color.Colors.green2)
                            .padding(.horizontal, 8) // 텍스트 필드와 이미지 주변 패딩
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundStyle(Color(Color.Fills.lightGreen))
                            }
                        
                        Text("쪽만 읽으면 돼요")
                        
                        Spacer()
                    }
                    
                } else {
                    HStack(alignment: .top) {
                        Text("쉬는 날을 선택할 수 있어요!\n원하지 않는다면 넘어가도 좋아요")
                        Spacer()
                    }
                }
            }
            .fontStyle(.title2, weight: .semibold)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .padding(.top, 34)
            .padding(.bottom, 17)
            .padding(.horizontal, 20)
            
            weekdayHeader()
                .padding(.horizontal, 20)
            
            Divider()
                .padding(.bottom, 20)
            
            calendarScrollView()
                .padding(.horizontal, 20)
            
            Spacer()
            
            Divider()
                .padding(.bottom, 14)
            
            nextButton()
                .padding(.horizontal, 16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectCompletionAction()
                } label: {
                    Text("완료")
                        .foregroundStyle(!(startDate == nil || endDate == nil) ?
                                         Color.Colors.green2
                                         : Color.Labels.tertiaryBlack3)
                }
                .disabled(startDate == nil || endDate == nil)
            }
        }
        .onAppear {
            let (tartgetEndPage, startPage) = (Int(bookSettingInputModel.targetEndPage)!, Int(bookSettingInputModel.startPage)!)
            
            totalPages = tartgetEndPage - startPage + 1
        }
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.dateSelection.setTracking()
        }
    }
    
    private func weekdayHeader() -> some View {
        HStack(spacing: 20) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .fontStyle(.caption1, weight: .semibold)
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
            }
        }
        .padding(.bottom, 12)
        
    }
    
    private func calendarScrollView() -> some View {
        ScrollView {
            VStack(spacing: 35) {
                ForEach(0..<12, id: \.self) { monthOffset in
                    let monthDate = Calendar.current.date(byAdding: .month, value: monthOffset, to: currentMonth)!
                    let daysInMonth = self.getDaysInMonth(for: monthDate)
                    
                    let adjustedDays = self.adjustDaysForMonth(monthDate: monthDate, daysInMonth: daysInMonth)
                    
                    VStack(spacing: 0) {
                        Text(monthDate.toKoreanDateStringWithoutDay())
                        // TODO: 폰트 확인하기
                            .fontStyle(.title3, weight: .semibold)
                            .padding(.bottom, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 16) {
                            ForEach(adjustedDays.indices, id: \.self) { index in
                                if let date = adjustedDays[index] {
                                    // 날짜가 현재 달에 속하고, 오늘 또는 선택된 날짜인 경우에만 셀 표시
                                    if let start = startDate, Calendar.current.isDate(date, inSameDayAs: start) {
                                        // startDate에 초기 값과 date의 날짜를 비교하고,
                                        // 같은 날에는 date 타입으로 셀을 만들지 않고 startDate로 셀을 추가한다.
                                        dateCell(for: start)
                                    } else {
                                        dateCell(for: date)
                                    }
                                } else {
                                    Color.clear.frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: 소거 로직 구현(배경색 조건에 따라 변경)
    private func dateCell(for date: Date) -> some View {
        let isPastDate = Calendar.current.compare(date, to: adjustedToday, toGranularity: .day) == .orderedAscending
        let isSelectedDay = isDaySelected(for: date)
        let isBetweenSelectedDays = isBetweenSelectedDays(for: date) && !deletedDates.contains(date)

        return ZStack {
            if isPastDate {
                dateText(for: date, isSelectedDay: false, textColor: Color.Labels.quaternaryBlack4) // 과거 날짜는 빨간색(//지금은 회색)
            } else {
                Group {
                    if isBetweenSelectedDays {
                        Rectangle()
                            .fill(Color.Fills.lightGreen)
                            .frame(height: 44)
                    } else if isSelectedDay {
                        dateSelectionRectangle(for: date)
                    }
                    dateText(for: date, isSelectedDay: isSelectedDay, textColor: Color.Labels.secondaryBlack2) // 기본 색상
                }
                .onTapGesture {
                    handleDateTap(for: date, isPastDate: isPastDate)
                }
            }
        }
    }
    
    private func handleDateTap(for date: Date, isPastDate: Bool) {
        // 과거 날짜에는 탭 제스처를 추가하지 않는다.
        guard !isPastDate else { return }
        
        if isDateSelectionLocked {
            if isBetweenSelectedDays(for: date) || deletedDates.contains(date) {
                toggleDateInDeletedDates(date)
            }
        } else {
            handleDateSelection(for: date)
        }
    }
    
    // MARK: 제외한 날짜를 배열에 추가
    private func toggleDateInDeletedDates(_ date: Date) {
        // 삭제된 날짜 목록에 조정된 날짜를 사용
        if let index = deletedDates.firstIndex(of: date) {
            deletedDates.remove(at: index)
            print("Removed adjusted date from deletedDates: \(date)")
        } else {
            deletedDates.append(date)
            print("Added adjusted date to deletedDates: \(date)")
        }
        deletedDates.sort()
        print("Current deletedDates: \(deletedDates)")
    }
    
    // 선택된 날짜(시작일, 종료일)
    private func dateText(for date: Date, isSelectedDay: Bool, textColor: Color) -> some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .frame(width: 44, height: 44)
//            .background(
//                isSelectedDay ? Color.green : Color.clear
//            )
            .foregroundStyle(isSelectedDay ? .white : textColor) // 선택된 경우 화이트, 그렇지 않으면 전달된 색상 사용
            .fontStyle(
                isSelectedDay ? .title2 : .body,
                weight: isSelectedDay ? .semibold : .regular
            )
//            .cornerRadius(26)
    }
    
    // 선택된 날짜 범위에 색칠 처리
    private func dateSelectionRectangle(for date: Date) -> some View {
        ZStack {
            HStack(spacing: 0) {
                // 선택된 시작 날짜
                if let start = startDate, date == start {
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.Fills.lightGreen)
                        .frame(height: 44)
                }
                // 선택된 종료 날짜
                else if let end = endDate, date == end {
                    Rectangle()
                        .fill(Color.Fills.lightGreen)
                        .frame(height: 44)
                    
                    Spacer()
                }
            }
            
            Circle()
                .fill(Color.Colors.green1)
                .frame(height: 44)
        }
    }
    
    // 날짜 선택 처리
    private func handleDateSelection(for date: Date) {
        let startOfDay = date // 날짜만 고려하고 시간은 무시
        
        if startDate == nil && endDate == nil {
            startDate = startOfDay
        } else if startDate == startOfDay {
            startDate = nil
        } else if endDate == startOfDay {
            endDate = nil
        } else if let endDate = endDate, startOfDay <= endDate {
            startDate = startOfDay
        } else if let startDate = startDate, startOfDay >= startDate {
            endDate = startOfDay
        }
    }
    
    // 날짜가 범위 내에 있는지 확인
    private func isBetweenSelectedDays(for date: Date) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        return date > start && date < end
    }
    
    // 선택된 날짜가 시작일이나 종료일인지 확인
    private func isDaySelected(for date: Date) -> Bool {
        return date == startDate || date == endDate
    }
    
    // 달의 첫 날짜와 일들을 일요일 기준으로 맞추는 함수
    private func adjustDaysForMonth(monthDate: Date, daysInMonth: [Date]) -> [Date?] {
        let calendar = Calendar.current
        let weekdayOfFirstDay = calendar.component(.weekday, from: monthDate.startOfMonth())
        
        // 첫날이 어떤 요일에 해당하는지, 1이 일요일인 것을 기준으로 계산
        let adjustedWeekdayOfFirstDay = weekdayOfFirstDay - 1 // 일요일을 0으로 하기 위해 -1
        let shiftDays = adjustedWeekdayOfFirstDay >= 0 ? adjustedWeekdayOfFirstDay : 6
        
        // 날짜 배열 생성, shiftDays만큼 빈 공간을 채운 후, 날짜 배열을 추가
        let adjustedDays = Array(repeating: nil, count: shiftDays) + daysInMonth
        return adjustedDays
    }
    
    // 날짜 계산
    private func getDaysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.compactMap { day -> Date? in
            let components = calendar.dateComponents([.year, .month], from: date)
            let adjustedDate = calendar.date(bySetting: .day, value: day, of: calendar.date(from: components)!)
            return adjustedDate.flatMap { calendar.startOfDay(for: $0) }
        }
    }
    
    // MARK: 버튼 로직 구현
    private func nextButton() -> some View {
        Button(action: nextButtonAction) {
            Text(isFirstClick ? "\(dayCount)일 동안 목표하기" : "완료")
                .fontStyle(.title2, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(startDate != nil && endDate != nil ? Color.Colors.green1 : Color.Fills.lightGreen)
                .foregroundStyle(.white)
                .cornerRadius(16)
        }
        .disabled(startDate == nil || endDate == nil)
    }
    
    private func nextButtonAction() {
        if isFirstClick {
            // TODO: 문구 변경
            isDateSelectionLocked = true
            isFirstClick = false
            
        } else {
            selectCompletionAction()
        }
    }
    
    private func selectCompletionAction() {
        // 입력 데이터 추가
        bookSettingInputModel.startData = startDate
        bookSettingInputModel.endData = endDate
        bookSettingInputModel.nonReadingDays = deletedDates
        
        // 페이지 이동
        bookSettingInputModel.nextPage()
    }
}
