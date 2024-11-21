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
}

extension UserBook {
    /// Date 타입의 값을 readingRecords의 키 값으로 사용할 수 있게 변환해주는 메서드
    func getReadingRecordsKey(_ date: Date) -> String { date.toYearMonthDayString() }
    func getAdjustedReadingRecordsKey(_ date: Date) -> String { date.toAdjustedYearMonthDayString() }
    
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
    
    /// 오늘 이후 다음 읽기 예정일을 반환하는 메서드
    func findNextReadingDay() -> Date? {
        let today = lastReadDate ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        print("today⭐️: \(today)")
        
        // 오늘 이후 날짜들 중 비독서일을 제외한 첫 읽기 예정일을 찾음
        for dateString in readingRecords.keys.sorted()
        where dateString > todayString {
            return dateFormatter.date(from: dateString)
        }
        // 모든 읽기 예정일이 지난 경우 nil 반환
        return nil
    }
    
    func findNextReadingPagesPerDay() -> Int {
        let readingScheduleCalculator = ReadingScheduleCalculator()
        
        return readingScheduleCalculator.calculatePagesPerDay(for: self).pagesPerDay
    }
    
    // TODO: 04시 기준으로 등록하기 ⏰
    /// 특정 날의 묙표량과 실제 읽은 페이지의 수를 가져오는 메서드 ⏰
    func getAdjustedReadingRecord(for date: Date) -> ReadingRecord? {
        let dateKey = self.getAdjustedReadingRecordsKey(date)
        print("💵💵💵💵: \(dateKey)")
        return self.readingRecords[dateKey]
    }
}
