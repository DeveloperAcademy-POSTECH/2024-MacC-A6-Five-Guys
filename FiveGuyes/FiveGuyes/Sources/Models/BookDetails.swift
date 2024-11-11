//
//  BookModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation
import SwiftData

@Model
final class BookDetails {
    let title: String
    let author: String
    let coverURL: String?
    let totalPages: Int
    
    var startDate: Date
    var targetEndDate: Date
    
    var nonReadingDays: [Date]
    
    init(title: String, author: String, coverURL: String? = nil, totalPages: Int, startDate: Date, targetEndDate: Date, nonReadingDays: [Date]) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
        self.startDate = startDate
        self.targetEndDate = targetEndDate
        self.nonReadingDays = nonReadingDays
    }
}

extension UserBook {
    // 더미 데이터 생성
    static var dummyUserBook: UserBook {
        let bookDetails = BookDetails(
            title: "더미 책 제목",
            author: "저자 이름",
            coverURL: nil,
            totalPages: 300,
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,  // 2주 전 시작일
            targetEndDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, nonReadingDays: []  // 1주 후 종료일
        )
        
        var userBook = UserBook(book: bookDetails)
        
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
