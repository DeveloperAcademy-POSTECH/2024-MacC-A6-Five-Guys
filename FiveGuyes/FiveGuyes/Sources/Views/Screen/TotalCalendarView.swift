//
//  TotalCalendarView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/6/24.
//



import SwiftUI

struct TotalCalendarView: View {
    
    struct ReadingData {
        let date: String
        var pagesRead: Int?
        var targetPages: Int?
        var currentPage: Int?
    }
    
    struct DateInfo {
        let formattedString: String
        let year: Int
        let month: Int
        let day: Int
    }
    
    // 더미데이터
    let totalBookPages = 260
    let totalTargetDays = 26
    var targetPagesPerDay: Int {
        totalBookPages / totalTargetDays
    }
    let todayDate = "2024-11-17" // 오늘은 17일이라고 가정 (더미데이터)
    //  let daysInMonth = 30 // 31 일 수도 있음. 11월이므로 30일이라고 가정 (더미데이터)
    // 직전(오늘 전)에 읽은 페이지 쪽 숫자 기록
    @State private var lastPageRead: Int?
    
    // 오늘 읽은 페이지 쪽 숫자 기록
    @State private var currentPageRead: Int?
    
    @State private var currentMonth: Date = Date()
    
    // 더미데이터 예시
    @State private var readingData: [ReadingData] = [
        ReadingData(date: "2024-11-01", pagesRead: nil, targetPages: nil, currentPage: nil), // 안읽기로 한 날
        ReadingData(date: "2024-11-02", pagesRead: 8, targetPages: 10, currentPage: 8),
        ReadingData(date: "2024-11-03", pagesRead: 15, targetPages: 20, currentPage: 23),
        ReadingData(date: "2024-11-04", pagesRead: 0, targetPages: 30, currentPage: 23),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-05", pagesRead: 12, targetPages: 40, currentPage: 35),
        ReadingData(date: "2024-11-06", pagesRead: 10, targetPages: 50, currentPage: 45),
        ReadingData(date: "2024-11-07", pagesRead: nil, targetPages: 60, currentPage: 45),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-08", pagesRead: nil, targetPages: nil, currentPage: 45), // 안읽기로 한 날
        ReadingData(date: "2024-11-09", pagesRead: 14, targetPages: 70, currentPage: 59),
        ReadingData(date: "2024-11-10", pagesRead: 7, targetPages: 80, currentPage: 66),
        ReadingData(date: "2024-11-11", pagesRead: 13, targetPages: 90, currentPage: 79),
        ReadingData(date: "2024-11-12", pagesRead: 10, targetPages: 100, currentPage: 89),
        ReadingData(date: "2024-11-13", pagesRead: 15, targetPages: 110, currentPage: 104),
        ReadingData(date: "2024-11-14", pagesRead: 7, targetPages: 120, currentPage: 111),
        ReadingData(date: "2024-11-15", pagesRead: nil, targetPages: nil, currentPage: 111), // 안읽기로 한 날
        ReadingData(date: "2024-11-16", pagesRead: 12, targetPages: 130, currentPage: 123),
        ReadingData(date: "2024-11-17", pagesRead: nil, targetPages: 140, currentPage: 123), // 오늘로 가정, 오늘 안읽음
        ReadingData(date: "2024-11-18", pagesRead: nil, targetPages: 150, currentPage: 123),
        ReadingData(date: "2024-11-19", pagesRead: nil, targetPages: 160, currentPage: 123), // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-20", pagesRead: nil, targetPages: 170, currentPage: 123),
        ReadingData(date: "2024-11-21", pagesRead: nil, targetPages: 180, currentPage: 123),
        ReadingData(date: "2024-11-22", pagesRead: nil, targetPages: nil, currentPage: 123), // 안읽기로 한 날
        ReadingData(date: "2024-11-23", pagesRead: nil, targetPages: 190, currentPage: 123),
        ReadingData(date: "2024-11-24", pagesRead: nil, targetPages: 200, currentPage: 123),
        ReadingData(date: "2024-11-25", pagesRead: nil, targetPages: 210, currentPage: 123),
        ReadingData(date: "2024-11-26", pagesRead: nil, targetPages: 220, currentPage: 123),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-27", pagesRead: nil, targetPages: 230, currentPage: 123),
        ReadingData(date: "2024-11-28", pagesRead: nil, targetPages: 240, currentPage: 123),
        ReadingData(date: "2024-11-29", pagesRead: nil, targetPages: nil, currentPage: 123), // 안읽기로 한 날
        ReadingData(date: "2024-11-30", pagesRead: nil, targetPages: 250, currentPage: 123)
    ]
    
    var body: some View {
        VStack {
            header
            dayLabels
            calendarDays
        }
        .padding()
    }
    
    private var header: some View {
        HStack {
            Text(monthYearString(for: currentMonth))
                .font(.title2)
                .bold()
            Spacer()
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    private var dayLabels: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var calendarDays: some View {
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            let (daysInMonth, startDayOfWeek) = getDateFromCalendar()
            let totalCells = startDayOfWeek + daysInMonth
            
            ForEach(0..<totalCells, id: \.self) { index in
                if index < startDayOfWeek {
                    
                    Text("")
                        .frame(width: 40, height: 40)
                } else {
                    
                    let day = index - startDayOfWeek + 1
                    let dateInfo = formattedDate(year: getCurrentMonthAndYear().year, month: getCurrentMonthAndYear().month, day: day)
                    VStack(spacing: 0) {
                        if let readingInfo = readingData.first(where: { $0.date == dateInfo.formattedString }) {
                            // 캘린더 그리기
                            // 오늘
                            if dateInfo.formattedString == todayDate {
                                Circle()
                                    .fill((Color(red: 0.07, green: 0.87, blue: 0.54))
)
                                    .frame(width: 40, height: 40)
                                    .overlay(Text("\(readingInfo.targetPages ?? 0)").font(.subheadline).foregroundColor(.white))
                            }
                            // 오늘이 아니면서
                            else {
                                // 계획하지 않은 날(타겟도 nil, 읽은 페이지도 nil) - 회색 원
                                if readingInfo.targetPages == nil && readingInfo.pagesRead == nil {
                                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 40, height: 40)
                                      }
                                
                                
                                // 계획 했고
                                else if  readingInfo.targetPages != nil {
                                    
                                    if let pagesRead = readingInfo.pagesRead, pagesRead > 0 {
                                        Circle()
                                        // 계획 했고 잘 읽은 날
                                            .fill(Color.green.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                            .overlay(Text("\(readingInfo.currentPage ?? 0)").font(.subheadline).foregroundColor(.black))
                                    }
                                    else {
                                        if isFutureDate(day: day, month: dateInfo.month, year: dateInfo.year) {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .overlay(Text("\(readingInfo.targetPages ?? 0)").font(.subheadline).foregroundColor(.white))
                                   
                                        } else {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .overlay(Text("•").font(.title).foregroundColor(.gray))
                                   
                                        }
                                    }
                                   
                                }
                               
                               
                              
                            
                            }
                           
                        }
                        else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                        }
                    }
                    .frame(width: 40, height: 40)
                }
            }
        }
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedDate(year: Int, month: Int, day: Int) -> DateInfo {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        guard let date = Calendar.current.date(from: components) else {
            return DateInfo(formattedString: "", year: 0, month: 0, day: 0)
        }
        
        let formattedString = formatter.string(from: date)
        return DateInfo(formattedString: formattedString, year: year, month: month, day: day)
    }
    
    private func getDateFromCalendar() -> (Int, Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        
        guard let firstDayOfCurrentMonth = calendar.date(from: components),
              let rangeOfMonth = calendar.range(of: .day, in: .month, for: firstDayOfCurrentMonth) else {
            return (0, 0)
        }
        
        let numberOfDaysInMonth = rangeOfMonth.count
        let startDayOfWeek = calendar.component(.weekday, from: firstDayOfCurrentMonth) - 1
        return (numberOfDaysInMonth, startDayOfWeek)
    }
    
    private func getCurrentMonthAndYear() -> (year: Int, month: Int) {
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        return (components.year ?? 2024, components.month ?? 1)
    }
    
    private func isFutureDate(day: Int, month: Int, year: Int) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let customTodayDate = dateFormatter.date(from: todayDate) else {
            return false
        }
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        if let comparisonDate = Calendar.current.date(from: components) {
            return comparisonDate > customTodayDate
        }
        
        return false
    }
}
