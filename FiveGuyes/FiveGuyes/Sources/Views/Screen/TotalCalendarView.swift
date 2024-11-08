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
        var todayReadPages: Int?
        var targetPages: Int?
        var currentPage: Int?
    }
    
    struct DateInfo {
        let formattedString: String
        let year: Int
        let month: Int
        let day: Int
    }
    
    // 내가 지금 보고 있는 달력의 월
    @State private var currentMonth: Date = Date()
    
    // 더미데이터
    // 전체 페이지 수
    // 여기서는 320 페이지라고 가정
    @State private var totalBookPages: Int?
    
    // 목표한 완독일 수(일부러 뺀 날짜 제외) 여기서는 32일로 가정
    @State private var totalTargetDays: Int?
    
    // 완독일(내가 정한 기간의 가장 마지막 일을 받아오기)
    // 여기서는 "2024-12-08"로 가정
    @State private var completionTargetDay: String? = "2024-12-08"
    
    // 하루 당 읽어야 하는 페이지 수 계산속성
    // 여기서는 320/32 = 10 장으로 가정
    private var targetPages: Int? {
        guard let totalBookPages = totalBookPages, let totalTargetDays = totalTargetDays else {
            return nil
        }
        return  totalBookPages / totalTargetDays
    }
    
   
    let todayDate = "2024-11-17" // 오늘은 17일이라고 가정 (더미데이터)
    
    // 직전(오늘 전)에 읽은 페이지 쪽 숫자 기록
    @State private var lastPageRead: Int?
    
    // 오늘 읽은 페이지 쪽 숫자 기록
    @State private var currentPageRead: Int?
    
    // 오늘 읽은 페이지 장 수
    private var todayReadPages: Int? {
        guard let currentPage = currentPageRead, let lastPage = lastPageRead else {
            return nil
        }
        return currentPage - lastPage
    }
    
    // 320장을 32일동안 읽기 위해 하루에 10페이지를 타겟으로 한다고 가정 한 더미데이터
    @State private var readingData: [ReadingData] = [
        ReadingData(date: "2024-11-01", todayReadPages: nil, targetPages: nil, currentPage: nil), // 안읽기로 한 날
        ReadingData(date: "2024-11-02", todayReadPages: 8, targetPages: 10, currentPage: 8),
        ReadingData(date: "2024-11-03", todayReadPages: 15, targetPages: 20, currentPage: 23),
        ReadingData(date: "2024-11-04", todayReadPages: 0, targetPages: 30, currentPage: 23),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-05", todayReadPages: 12, targetPages: 40, currentPage: 35),
        ReadingData(date: "2024-11-06", todayReadPages: 10, targetPages: 50, currentPage: 45),
        ReadingData(date: "2024-11-07", todayReadPages: nil, targetPages: 60, currentPage: 45),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-08", todayReadPages: nil, targetPages: nil, currentPage: 45), // 안읽기로 한 날
        ReadingData(date: "2024-11-09", todayReadPages: 14, targetPages: 70, currentPage: 59),
        ReadingData(date: "2024-11-10", todayReadPages: 7, targetPages: 80, currentPage: 66),
        ReadingData(date: "2024-11-11", todayReadPages: 13, targetPages: 90, currentPage: 79),
        ReadingData(date: "2024-11-12", todayReadPages: 10, targetPages: 100, currentPage: 89),
        ReadingData(date: "2024-11-13", todayReadPages: 15, targetPages: 110, currentPage: 104),
        ReadingData(date: "2024-11-14", todayReadPages: 7, targetPages: 120, currentPage: 111),
        ReadingData(date: "2024-11-15", todayReadPages: nil, targetPages: nil, currentPage: 111), // 안읽기로 한 날
        ReadingData(date: "2024-11-16", todayReadPages: 12, targetPages: 130, currentPage: 123),
        ReadingData(date: "2024-11-17", todayReadPages: 0, targetPages: 140, currentPage: 123), // 오늘로 가정, 오늘 안읽음
        ReadingData(date: "2024-11-18", todayReadPages: nil, targetPages: 150, currentPage: nil),
        ReadingData(date: "2024-11-19", todayReadPages: nil, targetPages: 160, currentPage: nil), // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-20", todayReadPages: nil, targetPages: 170, currentPage: nil),
        ReadingData(date: "2024-11-21", todayReadPages: nil, targetPages: 180, currentPage: nil),
        ReadingData(date: "2024-11-22", todayReadPages: nil, targetPages: nil, currentPage: nil), // 안읽기로 한 날
        ReadingData(date: "2024-11-23", todayReadPages: nil, targetPages: 190, currentPage: nil),
        ReadingData(date: "2024-11-24", todayReadPages: nil, targetPages: 200, currentPage: nil),
        ReadingData(date: "2024-11-25", todayReadPages: nil, targetPages: 210, currentPage: nil),
        ReadingData(date: "2024-11-26", todayReadPages: nil, targetPages: 220, currentPage: nil),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-11-27", todayReadPages: nil, targetPages: 230, currentPage: nil),
        ReadingData(date: "2024-11-28", todayReadPages: nil, targetPages: 240, currentPage: nil),
        ReadingData(date: "2024-11-29", todayReadPages: nil, targetPages: nil, currentPage: nil),  // 안읽기로 한 날
        ReadingData(date: "2024-11-30", todayReadPages: nil, targetPages: 250, currentPage: nil),
        ReadingData(date: "2024-12-01", todayReadPages: nil, targetPages: 260, currentPage: nil),
        ReadingData(date: "2024-12-02", todayReadPages: nil, targetPages: 270, currentPage: nil),
        ReadingData(date: "2024-12-03", todayReadPages: nil, targetPages: 280, currentPage: nil),
        ReadingData(date: "2024-12-04", todayReadPages: nil, targetPages: 290, currentPage: nil),  // 읽기로 했지만 안읽음
        ReadingData(date: "2024-12-05", todayReadPages: nil, targetPages: 300, currentPage: nil),
        ReadingData(date: "2024-12-06", todayReadPages: nil, targetPages: nil, currentPage: nil),  // 안읽기로 한 날
        ReadingData(date: "2024-12-07", todayReadPages: nil, targetPages: 310, currentPage: nil),
        ReadingData(date: "2024-12-08", todayReadPages: nil, targetPages: 320, currentPage: 320) // 완독일 12월 8일
    ]
    
    var body: some View {
        // 캘린더
        VStack {
            header
            dayLabels
            calendarDays
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 40)
        // 완독종료 표시
        HStack(alignment: .center) {
            
            Text("완독 종료일")
            Spacer()
            // 완독 종료 날짜 표시
            HStack(alignment: .center, spacing: 0) {
                Text("\(formattedCompletionDateString(from: completionTargetDay))")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Color(red: 0.93, green: 0.97, blue: 0.95))
            .cornerRadius(8)
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(width: 361, alignment: .center)
        // 구분선
        .overlay(
            VStack(spacing: 0) {
                Color(red: 0.94, green: 0.94, blue: 0.94)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        )
    }
    
    // 캘린더 헤더
    private var header: some View {
        ZStack {
            Text(calendarHeaderString(for: currentMonth))
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
          
            HStack(alignment: .center, spacing: 28) {
                Spacer()
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
                .padding(.trailing, 20)
            }
            .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))

        } 
        .padding(.bottom, 30)
    }
    
    // 캘린더 요일 라벨
    private var dayLabels: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.74, green: 0.74, blue: 0.74))
                    .frame(width: 32, height: 18, alignment: .center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 23)
    }
    
    private var calendarDays: some View {
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            let (daysInMonth, startDayOfWeek) = getDateFromCalendar()
            let totalCells = startDayOfWeek + daysInMonth
            
            ForEach(0..<totalCells, id: \.self) { index in
                if index < startDayOfWeek {
                    Text("")
                        .frame(width: 50, height: 50)
                } else {
                    let day = index - startDayOfWeek + 1
                    let dateInfo = formattedDate(year: getCurrentMonthAndYear().year, month: getCurrentMonthAndYear().month, day: day)
                    VStack(spacing: 0) {
                        if let readingInfo = readingData.first(where: { $0.date == dateInfo.formattedString }) {
                            
                            // 완독일 인 경우
                            if dateInfo.formattedString == completionDateFormatted {
                                ZStack {
                                    Image("flag")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    VStack {
                                        Text("완독")
                                            .font(.system(size: 13))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                                    }
                                }
                            }
                            // 오늘인 경우
                           else if dateInfo.formattedString == todayDate {
                                TotalCalendarTextBubble(text: "\(readingInfo.targetPages ?? 0)", textColor: .white, backgroundColor: Color(red: 0.07, green: 0.87, blue: 0.54))
                            }
                            // 오늘이 아니면서
                            else {
                                // 계획하지 않은 날(타겟도 nil, 읽은 페이지도 nil) - 회색 원
                                if readingInfo.targetPages == nil && readingInfo.todayReadPages == nil {
                                    TotalCalendarTextBubble(text: "", textColor: Color.clear, backgroundColor: Color(red: 0.97, green: 0.98, blue: 0.97))
                                }
                                // 계획 했고
                                else if  readingInfo.targetPages != nil {
                                    
                                    if let pagesRead = readingInfo.todayReadPages, pagesRead > 0 {
                                        // 계획 했고 잘 읽은 날
                                        TotalCalendarTextBubble(text: "\(readingInfo.currentPage ?? 0)", textColor: .black, backgroundColor: Color.green.opacity(0.2))
                                    } else {
                                        if isFutureDate(day: day, month: dateInfo.month, year: dateInfo.year) {
                                            TotalCalendarTextBubble(text: "\(readingInfo.targetPages ?? 0)", textColor: Color(red: 0.84, green: 0.84, blue: 0.84), backgroundColor: .clear)
                                        } else {
                                            TotalCalendarTextBubble(text: "•", textColor: .gray, backgroundColor: Color(red: 0.97, green: 0.98, blue: 0.97))
                                        }
                                    }
                                }
                            }
                        } else {
                            TotalCalendarTextBubble(text: "", textColor: Color.clear, backgroundColor: Color.gray.opacity(0.2))
                        }
                    }
                    .frame(width: 50, height: 50, alignment: .center)
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
    
    // 캘린더 헤더용 스트링 변환 로직
    private func calendarHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy MMMM"
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
    
    // 완독 종료일 스트링을 표시하기 위한 로직
    // 완료일을 completionTargetDay로 가져오는 경우
    private func formattedCompletionDateString(from dateString: String?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let dateString = dateString else { return "변환하지 못했습니다" }
        guard let date = dateFormatter.date(from: dateString) else {
            return "유효하지 않은 날짜 형식입니다"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ko_KR")
        displayFormatter.dateFormat = "M월 d일 EEEE"
        
        return displayFormatter.string(from: date)
    }
    
    // 캘린더 내 플래그 완독 표시를 위한 로직
    private var completionDateFormatted: String {
      
        let lastReadingData = readingData.last(where: { $0.targetPages == $0.currentPage })
        
        guard let lastDate = lastReadingData?.date else {
            return "완독이 완료되지 않았습니다"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
   
        guard let date = dateFormatter.date(from: lastDate) else {
            return "유효하지 않은 데이터포맷임"
        }
        
        return dateFormatter.string(from: date)
    }
    
}
