//
//  WeeklyPageCalendarView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

struct WeeklyPageCalendarView: View {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    let currentReadingBook: UserBook
    
    let today = Date()
    
    // TODO: 특정 날짜 이전 요일들의 UI 수정
    var body: some View {
        let weeklyRecords = currentReadingBook.getAdjustedWeeklyRecorded(from: today)
        let todayIndex = Calendar.current.getAdjustedWeekdayIndex(from: today)
        
        HStack(spacing: 0) { // 셀 간격을 없앰으로써 연결된 배경처럼 보이게 설정
            ForEach(0..<daysOfWeek.count, id: \.self) { index in
                VStack(spacing: 5) {
                    Text(daysOfWeek[index]) // 요일 표시
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                    
                    ZStack {
                        // MARK: 뒷 배경 관련 코드
                        if todayIndex != 0 { // 일요일인경우 뒷 배경 필요 없음
                            if index <= todayIndex {
                                if index == 0 {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(.white)
                                            .frame(height: 44)
                                        
                                        Rectangle()
                                            .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                            .frame(height: 44)
                                    }
                                    
                                    Circle()
                                        .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                        .frame(height: 44)
                                    
                                } else if index == todayIndex {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                            .frame(height: 44)
                                            .shadow(radius: 0)
                                        
                                        Rectangle()
                                            .fill(.white)
                                            .frame(height: 44)
                                            .shadow(radius: 0)
                                    }
                                    
                                } else {
                                    Rectangle()
                                        .fill(Color(red: 0.93, green: 0.97, blue: 0.95))
                                        .frame(height: 44)
                                }
                            }
                        }
                        
                        // MARK: 페이지 분량 관련 코드
                        if let record = weeklyRecords[index] { // 페이지 할당이 되어있다면
                            let hasCompletedToday = record.pagesRead == record.targetPages
                            
                            if index < todayIndex {
                                    Text(hasCompletedToday ? "\(record.pagesRead)" : "•")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.black)
                                        .frame(height: 44)
                            } else if index == todayIndex { // today
                                    Circle()
                                        .fill(hasCompletedToday ?
                                              Color(red: 0.07, green: 0.87, blue: 0.54) :
                                                Color(red: 0.84, green: 0.97, blue: 0.88)
                                        )
                                        .frame(height: 44)
                                    
                                    Text("\(record.targetPages)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(height: 44)
                            } else {
                                Text("\(record.targetPages)")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                                    .frame(height: 44)
                            }
                        } else { // 페이지 할당이 없다면
                            if index == todayIndex { // today
                                Circle()
                                    .fill(Color(red: 0.07, green: 0.87, blue: 0.54))
                                    .frame(height: 44)
                            }
                            Text("")
                                .frame(height: 44)
                                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct WeeklyPageCalendarView_Previews: PreviewProvider {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    static var previews: some View {
        WeeklyPageCalendarView(currentReadingBook: UserBook.dummyUserBook)
    }
    
    // 더미 데이터 생성
    static var dummyUserBook: UserBook {
        let bookDetails = BookDetails(
            title: "더미 책 제목",
            author: "저자 이름",
            coverURL: nil,
            totalPages: 300,
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,  // 2주 전 시작일
            targetEndDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            nonReadingDays: []  // 1주 후 종료일
        )
        
        let userBook = UserBook(book: bookDetails)
        
        // 더미 읽기 기록 추가
        let calendar = Calendar.current
        for dayOffset in -6...6 {  // 지난주 일요일부터 다음 주 토요일까지
            let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
            let dateKey = date.toYearMonthDayString()
            
            let targetPages = 20
            let pagesRead = dayOffset < 0 ? targetPages : (dayOffset == 0 ? 15 : 0)  // 과거에는 목표를 달성, 오늘은 일부 읽음, 미래는 읽지 않음
            
            userBook.readingRecords[dateKey] = ReadingRecord(targetPages: targetPages, pagesRead: pagesRead)
        }
        
        return userBook
    }
}
