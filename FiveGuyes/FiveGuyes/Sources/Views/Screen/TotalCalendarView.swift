//
//  TotalCalendarView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/6/24.
//


import SwiftUI

struct TotalCalendarView: View {
   
    
    // 더미데이터
    let totalBookPages = 260
    let totalTargetDays = 26
    var targetPagesPerDay: Int {
        totalBookPages / totalTargetDays
    }
    let todayDate = "2024-11-17" // 오늘은 17일이라고 가정 (더미데이터)
    let daysInMonth = 30 // 31 일 수도 있음. 11월이므로 30일이라고 가정 (더미데이터)
    // 직전(오늘 전)에 읽은 페이지 쪽 숫자 기록
    @State private var lastPageRead: Int? = nil
    
    // 오늘 읽은 페이지 쪽 숫자 기록
    @State private var currentPageRead: Int? = nil

    @State private var currentMonth: Date = Date()
    
    // 더미데이터 예시
    @State private var readingData: [(date: String, pagesRead: Int?, targetPages: Int?, currentPage: Int?)] = [
        ("2024-11-01", nil, nil, nil), // 안읽기로 한 날
        ("2024-11-02", 8, 10, 8),
        ("2024-11-03", 15, 20, 23),
        ("2024-11-04", 0, 30, 23),  // 읽기로 했지만 안읽음
        ("2024-11-05", 12, 40, 35),
        ("2024-11-06", 10, 50, 45),
        ("2024-11-07", nil, 60, 45),  // 읽기로 했지만 안읽음
        ("2024-11-08", nil, nil, 45), // 안읽기로 한 날
        ("2024-11-09", 14, 70, 59),
        ("2024-11-10", 7, 80, 66),
        ("2024-11-11", 13, 90, 79),
        ("2024-11-12", 10, 100, 89),
        ("2024-11-13", 15, 110, 104),
        ("2024-11-14", 7, 120, 111),
        ("2024-11-15", nil, nil, 111), // 안읽기로 한 날
        ("2024-11-16", 12, 130, 123),
        ("2024-11-17", nil, 140, 123), // 오늘로 가정, 오늘 안읽음
        ("2024-11-18", 10, 150, 123),
        ("2024-11-19", nil, 160, 123), // 읽기로 했지만 안읽음
        ("2024-11-20", nil, 170, 123),
        ("2024-11-21", nil, 180, 123),
        ("2024-11-22", nil, nil, 123), // 안읽기로 한 날
        ("2024-11-23", nil, 190, 123),
        ("2024-11-24", nil, 200, 123),
        ("2024-11-25", nil, 210, 123),
        ("2024-11-26", nil, 220, 123),  // 읽기로 했지만 안읽음
        ("2024-11-27", nil, 230, 123),
        ("2024-11-28", nil, 240, 123),
        ("2024-11-29", nil, nil, 123), // 안읽기로 한 날
        ("2024-11-30", nil, 250, 123)
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
                
                ForEach(1...daysInMonth, id: \.self) { day in
                    let formattedDay = formattedDate(for: day)
                    
                    VStack {
                        if let readingInfo = readingData.first(where: { $0.date == formattedDay }) {
                            // 날짜를 가져옵니다
                            VStack {
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
                                    if formattedDay == todayDate || isFutureDate(day: day) {
                                        Circle()
                                            .strokeBorder(Color.gray, lineWidth: 1)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("\(readingInfo.targetPages ?? 0)")
                                                // 타겟 한 페이지를 보여준다
                                                    .font(.subheadline)
                                                    .foregroundColor(.black)
                                            )
                                    }
                                    else {
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
                                    if formattedDay == todayDate || isFutureDate(day: day) {
                                        Circle()
                                            .strokeBorder(Color.gray, lineWidth: 1)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("\(readingInfo.targetPages ?? 0)")
                                                // 타겟 한 페이지를 보여준다
                                                    .font(.subheadline)
                                                    .foregroundColor(.black)
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
                        } else if isFutureDate(day: day) {
                            // 아직 스케줄에 없는 미래 날짜는 칠해지지않은 회색 원으로 표시합니다
                            Circle()
                                .strokeBorder(Color.gray, lineWidth: 1)
                                .frame(width: 40, height: 40)
                        }
                        
                    }
                    .padding(5)
                }
            }
            .padding()
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
    
    //더미데이터용 미래판별함수, 현재받아오늘 날짜 데이터를 2024-11-17 스트링으로 가정할때
    //앞서 가정한    let todayDate = "2024-11-17" // 오늘은 17일이라고 가정 (더미데이터) 를 사용하기 위함임
    func isFutureDate(day: Int) -> Bool {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let customTodayDate = dateFormatter.date(from: todayDate) else {
            return false
        }
        
       
        var components = Calendar.current.dateComponents([.year, .month], from: customTodayDate)
        components.day = day
       
        if let comparisonDate = Calendar.current.date(from: components) {
            return comparisonDate > customTodayDate
        }
        
        return false
    }

    
    // 미래를 판별(실제 데이터일때)
    /*
    func isFutureDate(day: Int) -> Bool {
        let today = Date()
        var components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        components.day = day
        if let date = Calendar.current.date(from: components) {
            return date > today
        }
        return false
    }
    */
    // 아마 호랑이 구현하고 있는 페이지 계산함수 임의로 만들어봄
    func updatePagesRead(for date: String) {
        guard let lastPage = lastPageRead, let currentPage = currentPageRead else { return }
        
        let pagesReadToday = currentPage - lastPage
        if let index = readingData.firstIndex(where: { $0.date == date }) {
            readingData[index].pagesRead = pagesReadToday
            lastPageRead = currentPage
        }
    }
    
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

