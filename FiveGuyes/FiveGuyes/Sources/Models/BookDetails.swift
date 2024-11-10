//
//  BookModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

@Observable
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

struct ReadingRecord {
    var targetPages: Int   // 목표로 설정된 페이지 수
    var pagesRead: Int     // 실제 읽은 페이지 수
}

@Observable
final class UserBook {
    var book: BookDetails
    var readingRecords: [String: ReadingRecord] = [:] // Keyed by formatted date strings
    
    // 계산 로직을 더 편하게 하기 위해 마지막으로 읽은 날의 결과를 따로 저장합니다.
    var lastReadDate: Date? // 마지막 읽은 날짜
    var lastPagesRead: Int = 0 // 마지막으로 읽은 페이지 수
    
    var completionReview = ""
    
    init(book: BookDetails) {
        self.book = book
    }
    
    /// `pagesRead`가 0이 아닌 날의 수를 반환합니다.
    /// 지금까지 독서를 한 날의 수
    func nonZeroReadingDaysCount() -> Int {
        // 첫 날은 1일 째 도전중이니까 + 1을 해준다.
        let readingDays = readingRecords.values.filter { $0.pagesRead > 0 }
        if readingDays.isEmpty {
            return 1
        }
        return readingRecords.values.filter { $0.pagesRead > 0 }.count
    }
}

@Observable
final class UserLibrary {
    var currentReadingBook: UserBook?
    var completedBooks: [UserBook?] = []
    
    /// 현재 읽고 있는 책을 완독 처리하고, `completedBooks`에 추가합니다.
    func completeCurrentBook(_ book: UserBook, review: String) {
        // 책의 완독 날짜를 오늘로 설정
        book.book.targetEndDate = Date()
        book.completionReview = review

        // 시작 날짜가 종료 날짜보다 이후에 있으면 시작 날짜도 완료 날짜로 설정
        if book.book.startDate > book.book.targetEndDate {
            book.book.startDate = book.book.targetEndDate
        }
        
        // 완독한 책을 completedBooks에 추가하고 currentReadingBook을 nil로 설정
        completedBooks.append(book)
        currentReadingBook = nil
    }
    
    func deleteCurrentBook() {
        currentReadingBook = nil
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
