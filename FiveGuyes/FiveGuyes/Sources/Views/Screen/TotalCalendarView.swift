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
    
    // 더미데이터
    let totalBookPages = 260
    let totalTargetDays = 26
    var targetPagesPerDay: Int {
        totalBookPages / totalTargetDays
    }
    let todayDate = "2024-11-17" // 오늘은 17일이라고 가정 (더미데이터)
    let daysInMonth = 30 // 31 일 수도 있음. 11월이므로 30일이라고 가정 (더미데이터)
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
        ReadingData(date: "2024-11-18", pagesRead: 10, targetPages: 150, currentPage: 123),
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
        Text("전체 독서현황")
        
        // 캘린더
        VStack {
            HStack {
                Text(monthYearString(for: currentMonth))
                    .font(.title2)
                    .bold()
                Spacer()
                HStack(spacing: 28) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                    }
                }
                
            }
            .padding()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
                
                ForEach(1...daysInMonth, id: \.self) { day in
                    let formattedDay = formattedDate(for: day)
                    let (month, year) = getCurrentMonthAndYear()
                    
                    VStack(spacing: 0) {
                        if let readingInfo = readingData.first(where: { $0.date == formattedDay }) {
                            // 날짜를 가져옵니다
                            VStack(spacing: 0) {
                                // 해당 날짜의 타겟페이지가 nil 이라면 계획하지 않은 날이므로 꽉찬 회색원을 그립니다
                                if readingInfo.targetPages == nil {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                }
                                // 계획한 날짜중에서 이제 로직을 작성합니다.
                                // 판단을 위해 페이지를 읽은 날 , 즉 nil이 아니면서도 0을 초과한 날을 골라냅니다.
                                else if let pagesRead = readingInfo.pagesRead, pagesRead > 0 {
                                    // 지정된 페이지를 읽은 날
                                    // 이때 현재 시점에 대한 판단이 필요합니다.
                                    // 0을 초과한 날중에서 현재보다 미래인 경우, 혹은 현재인 경우(오늘의 경우) 타겟페이지를 보여줍니다
                                    // month,
                                    if formattedDay == todayDate || isFutureDate(day: day, month: month, year: year) {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("\(readingInfo.targetPages ?? 0)")
                                                // 타겟 한 페이지를 보여준다
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            )
                                    } else {
                                        // 과거의 기록이라면 초록색 동그라미를 줍니다.그 안에는 오늘 읽은 페이지가 들어있습니다.
                                        if let currentPage = readingInfo.currentPage {
                                            Circle()
                                                .fill(Color.green.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text("\(currentPage)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.black)
                                                )
                                        }
                                    }
                                    
                                } else {
                                    // 0 페이지 읽거나 값이 없는 날짜 (nil 인경우) 인데
                                    // 미래라면 타겟한 페이지를 보여주고
                                    if formattedDay == todayDate || isFutureDate(day: day, month: month, year: year) {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("\(readingInfo.targetPages ?? 0)")
                                                // 타겟 한 페이지를 보여준다
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    // 과거라면
                                    else {
                                        // 회색원에 점이 찍힌 결석표시를 보여줍니다
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("•")
                                                // 회색원에 점이 찍힌 것을 보여준다
                                                    .font(.title)
                                                    .foregroundColor(.gray)
                                            )
                                        
                                    }
                                    
                                }
                            }
                        } else if isFutureDate(day: day, month: month, year: year) {
                            // 아직 스케줄에 없는 미래 날짜는 칠해지지않은 회색 원으로 표시합니다
                            // TODO: 로직 보완 또는 추가
                            // 미래날짜를 판별하는 기준을 현재는 현재 보고있는 달력을 기준으로 하고 있는데 이후 추후 로직필요할듯(?)
                            Circle()
                                .strokeBorder(Color.gray, lineWidth: 1)
                                .frame(width: 40, height: 40)
                        }
                        
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func formattedDate(for day: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        components.day = day
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }
    
    // 달력에서 월, 연도를 가져옴
    func getCurrentMonthAndYear() -> (Int, Int) {
        let components = Calendar.current.dateComponents([.month, .year], from: currentMonth)
        return (components.month ?? 1, components.year ?? 2024)
    }
    
    //단 이 함수는 일 만을 판별함 (연, 월은 판별하지 않음)
    //더미데이터용 미래판별함수, 현재받아오늘 날짜 데이터를 2024-11-17 스트링으로 가정할때
    //앞서 가정한    let todayDate = "2024-11-17" // 오늘은 17일이라고 가정 (더미데이터) 를 사용하기 위함임
    func isFutureDate(day: Int, month: Int, year: Int) -> Bool {
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
    
    
    // 아마 호랑이 구현하고 있는 페이지 계산함수 임의로 만들어봄
    func updatePagesRead(for date: String) {
        guard let lastPage = lastPageRead, let currentPage = currentPageRead else { return }
        
        let pagesReadToday = currentPage - lastPage
        if let index = readingData.firstIndex(where: { $0.date == date }) {
            readingData[index].pagesRead = pagesReadToday
            lastPageRead = currentPage
        }
    }
    
    // TODO: 실제로 제대로 동작하는지 확인필요
    // 결석해서 다음날 고생해야되는 페이지 누적 로직
    func applyRolloverQuota() {
        var accumulatedTarget = 0
        
        for i in 0..<readingData.count {
            // 의도적으로 뺀 날인지 확인
            if readingData[i].targetPages == nil {
                // 누적 페이지를 할당하지 않음
                accumulatedTarget = 0
                continue
            }
            
            // 잘 읽은 날(0이나 nil이 아닌 날)
            if let pagesRead = readingData[i].pagesRead, pagesRead > 0 {
                // 누적페이지를 할당하지 않음
                accumulatedTarget = 0
            } else {
                // 타겟페이지가 0이나 nil 인 날
                // 누적페이지를 타겟페이지만큼 더 할당함
                accumulatedTarget += targetPagesPerDay
            }
            
            // 오늘 읽어야하는 페이지에 누적페이지를 더함
            readingData[i].targetPages = (readingData[i].targetPages ?? 0) + accumulatedTarget
        }
    }
    
}

#Preview {
    TotalCalendarView()
}
