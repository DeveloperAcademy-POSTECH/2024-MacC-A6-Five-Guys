//
//  TotalCalendarView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/6/24.
//

import SwiftUI

struct TotalCalendarView: View {
    
    // MARK: - Properties
    
    @State private var currentIndex: Int? = 0
    
    @State private var currentMonths: [Date]
    private let todayDate = Date().adjustedDate()
    
    let currentReadingBooks: [FGUserBook]
    
    // MARK: - Initializer
    
    init(currentReadingBooks: [FGUserBook]) {
        self.currentReadingBooks = currentReadingBooks
        _currentMonths = State(initialValue: currentReadingBooks.map { _ in Date().adjustedDate() })
    }
    
    // MARK: - Layout
    
    var body: some View {
        VStack(spacing: 0) {
            bookInfoHeader(for: currentReadingBooks[currentIndex ?? 0])
                .padding(.top, 9)
                .padding(.bottom, 8)
                .padding(.horizontal, 20)
            
            indicatorView()
                .padding(.bottom, 22)
                .padding(.horizontal, 20)
            
            calendarScrollView()
            
            Spacer()
        }
        .navigationTitle("전체 독서 현황")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.calendarView.setTracking()
        }
    }
    
    // MARK: - Subviews
    
    private func bookInfoHeader(for book: FGUserBook) -> some View {
        HStack(alignment: .top) {
            Text(book.bookMetaData.title)
                .fontStyle(.title1, weight: .semibold)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .foregroundStyle(Color.Labels.primaryBlack1)
            
            Spacer()
            
            if let coverImageURLString = book.bookMetaData.coverImageURL,
               let url = URL(string: coverImageURLString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 68)
                        .clipRightSideRounded(radius: 8)
                } placeholder: {
                    ProgressView()
                }
            }
        }
    }
    
    private func indicatorView() -> some View {
        HStack(spacing: 2) {
            ForEach(currentReadingBooks.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.Labels.primaryBlack1 : Color.Labels.quaternaryBlack4)
                    .frame(width: 4, height: 4)
            }
            
            Spacer()
        }
    }
    
    // TODO: - 디자이너 작업 중
    private func calendarScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(currentReadingBooks.indices, id: \.self) { index in
                    VStack(spacing: 0) {
                        header(for: index)
                            .padding(.top, 24)
                            .padding(.bottom, 23)
                        
                        dayLabels
                            .padding(.bottom, 22)
                        
                        calendarDays(for: currentReadingBooks[index], index: index)
                            .padding(.horizontal, 5)
                            .padding(.bottom, 16)
                        
                        Divider()
                            .padding(.bottom, 12)
                        
                        CompletionFooter(for: currentReadingBooks[index])
                            .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .inset(by: 0.5)
                            .stroke(Color.Separators.green, lineWidth: 1)
                            .foregroundStyle(Color.Backgrounds.primary)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width - 48)
//                    .containerRelativeFrame(.horizontal)
                    .id(index)
                }
            }
            .safeAreaPadding(.horizontal, 24)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentIndex)
    }
    
    private func header(for index: Int) -> some View {
        HStack(spacing: 0) {
            Text(calendarHeaderString(for: currentMonths[index]))
                .fontStyle(.body, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Labels.primaryBlack1)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 24) {
                Spacer()
                
                Button {
                    previousMonth(index)
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Button {
                    nextMonth(index)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(Color.Colors.green2)
        }
    }
    
    private var dayLabels: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .fontStyle(.caption2, weight: .semibold) // TODO: 디자이너 확인중
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
                    .frame(width: 32, height: 18, alignment: .center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private func calendarDays(for currentReadingBook: FGUserBook, index: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            let (daysInMonth, startDayOfWeek) = getDateFromCalendar(for: index)
            let totalCells = startDayOfWeek + daysInMonth
            
            ForEach(0..<totalCells, id: \.self) { cellIndex in
                calendarDayCell(
                    cellIndex: cellIndex,
                    startDayOfWeek: startDayOfWeek,
                    currentReadingBook: currentReadingBook,
                    index: index
                )
            }
        }
    }

    private func calendarDayCell(
        cellIndex: Int,
        startDayOfWeek: Int,
        currentReadingBook: FGUserBook,
        index: Int
    ) -> some View {
        if cellIndex < startDayOfWeek {
            return AnyView(Text("")
                .frame(width: 50, height: 50))
        } else {
            let day = cellIndex - startDayOfWeek + 1
            
            guard let date = Calendar.current.date(
                from: DateComponents(
                    year: getCurrentMonthAndYear(for: index).year,
                    month: getCurrentMonthAndYear(for: index).month,
                    day: day)
            ) else {
                return AnyView(EmptyView())
            }
            
            let dateKey = date.toYearMonthDayString()
            
            return AnyView(calendarDayContent(date: date, dateKey: dateKey, currentReadingBook: currentReadingBook))
        }
    }

    private func calendarDayContent(date: Date, dateKey: String, currentReadingBook: FGUserBook) -> some View {
        VStack(spacing: 0) {
            if let readingRecord = currentReadingBook.readingProgress.dailyReadingRecords[dateKey] {
                let isTodayCompletionDate = Calendar.current.isDate(todayDate,inSameDayAs: currentReadingBook.userSettings.targetEndDate)
                
                if Calendar.current.isDate(date, inSameDayAs: currentReadingBook.userSettings.targetEndDate) {
                    Image(isTodayCompletionDate ? "completionGreenFlag" : "completionFlag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("완독")
                                .fontStyle(.caption1, weight: .semibold)
                                .foregroundStyle(isTodayCompletionDate ? Color.Fills.white : Color.Colors.green2)
                                .padding(.bottom, 1)
                                .padding(.leading, 2)
                        )
                } else if Calendar.current.isDate(date, inSameDayAs: todayDate) {
                    // 오늘 날짜인 경우 - 초록색 배경에 목표 페이지 수 표시
                    TotalCalendarTextBubble(
                        text: "\(readingRecord.targetPages)",
                        textColor: Color.Fills.white,
                        backgroundColor: Color.Colors.green1,
                        fontWeight: .regular,
                        fontSize: .title2
                    )
                } else if readingRecord.pagesRead == readingRecord.targetPages {
                    // 목표 페이지를 달성한 날 - 녹색 배경의 읽은 페이지 수 표시
                    TotalCalendarTextBubble(
                        text: "\(readingRecord.pagesRead)",
                        textColor: Color.Labels.secondaryBlack2,
                        backgroundColor: Color.Colors.green
                    )
                } else if date > todayDate {
                    // 미래의 날짜로 계획이 설정된 날 - 회색 텍스트로 목표 페이지 수 표시
                    TotalCalendarTextBubble(
                        text: "\(readingRecord.targetPages)",
                        textColor: Color.Labels.quaternaryBlack4,
                        backgroundColor: .clear
                    )
                } else {
                    // 과거 날짜에서 계획은 설정되었지만, 읽지 않은 날 - 회색 점으로 결석 표시
                    TotalCalendarTextBubble(
                        text: "•",
                        textColor: Color.Labels.secondaryBlack2,
                        backgroundColor: Color.Fills.lightGreen
                    )
                }
            } else {
                // 계획되지 않은 날 - 빈 배경
                TotalCalendarTextBubble(
                    text: "",
                    textColor: Color.clear,
                    backgroundColor: Color.Fills.lightGreen
                )
            }}
        .frame(width: 50, height: 50, alignment: .center)
    }
    
    private func CompletionFooter(for currentReadingBook: FGUserBook) -> some View {
        HStack(alignment: .center) {
            Text("완독 종료일")
                .fontStyle(.body, weight: .semibold)
            
            Spacer()
            
            Text("\(formattedCompletionDateString(from: currentReadingBook.userSettings.targetEndDate))")
                .fontStyle(.body, weight: .regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Colors.green2)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Color.Fills.lightGreen)
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Month Navigation
    
    private func previousMonth(_ index: Int) {
        currentMonths[index] = Calendar.current.date(byAdding: .month, value: -1, to: currentMonths[index]) ?? currentMonths[index]
    }
    
    private func nextMonth(_ index: Int) {
        currentMonths[index] = Calendar.current.date(byAdding: .month, value: 1, to: currentMonths[index]) ?? currentMonths[index]
    }
    
    // MARK: - Date Formatting
    
    private func calendarHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    
    private func getDateFromCalendar(for index: Int) -> (Int, Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonths[index])
        guard let firstDayOfCurrentMonth = calendar.date(from: components),
              let rangeOfMonth = calendar.range(of: .day, in: .month, for: firstDayOfCurrentMonth) else {
            return (0, 0)
        }
        
        let numberOfDaysInMonth = rangeOfMonth.count
        let startDayOfWeek = calendar.component(.weekday, from: firstDayOfCurrentMonth) - 1
        return (numberOfDaysInMonth, startDayOfWeek)
    }
    
    private func getCurrentMonthAndYear(for index: Int) -> (year: Int, month: Int) {
        let date = currentMonths.indices.contains(index) ? currentMonths[index] : Date().adjustedDate()
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return (components.year ?? 2024, components.month ?? 1)
    }
    
    private func formattedCompletionDateString(from date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M월 d일 EEEE"
        return displayFormatter.string(from: date)
    }
}
