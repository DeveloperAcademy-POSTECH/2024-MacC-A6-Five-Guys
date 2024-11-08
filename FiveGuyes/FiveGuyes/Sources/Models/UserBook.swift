//
//  UserBook.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/11/24.
//

import Foundation
import SwiftData

struct ReadingRecord: Codable {
    var targetPages: Int   // 목표로 설정된 페이지 수
    var pagesRead: Int     // 실제 읽은 페이지 수
}

@Model
final class UserBook {
    @Attribute(.unique) var id = UUID()
    var book: BookDetails
    
    var readingRecords: [String: ReadingRecord] = [:] // Keyed by formatted date strings
    
    // 계산 로직을 더 편하게 하기 위해 마지막으로 읽은 날의 결과를 따로 저장합니다.
    var lastReadDate: Date? // 마지막 읽은 날짜
    var lastPagesRead: Int = 0 // 마지막으로 읽은 페이지 수
    
    var completionReview = ""
    var isCompleted: Bool = false  // 현재 읽는 중인지 완독한 책인지 표시
    
    init(book: BookDetails) {
        self.book = book
    }
    
    func markAsCompleted(review: String) {
        // 책을 완독 상태로 설정
        book.targetEndDate = Date()
        completionReview = review
        isCompleted = true
        
        // 필요한 경우 시작 날짜와 종료 날짜를 조정
        if book.startDate > book.targetEndDate {
            book.startDate = book.targetEndDate
        }
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