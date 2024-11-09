//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

// TODO: 기간이 페이지보다 긴 경우 예외 처리하기 (기간이 너무 길다고 표현)
// TODO: 중간에 목표를 넘으면 중단시키기
// TODO: dailyTargets도 책과 함께 로컬에 저장해야 하는 것 생각
// TODO: 완독 날짜 변경하는 상황 고려

struct ReadingScheduleCalculator {
    
    // TODO: Date 타입의 extension 메서드로 옮기기
    // 데이터의 키 값을 파싱해서 가져오는 메서드
    private func toYearMonthDayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC 시간대 설정
        return formatter.string(from: date)
    }
    
    // 첫날을 기준으로 읽어야하는 페이지를 할당하는 메서드
    func calculateInitialDailyTargets(for currentReadingBook: UserBook) {
        let totalReadingDays = calculateTotalReadingDays(for: currentReadingBook)
        let pagesPerDay = calculatePagesPerDay(for: currentReadingBook)
        let remainderPages = calculateRemainderPages(for: currentReadingBook)
        
        var targetDate = currentReadingBook.book.startDate
        var remainderOffset = remainderPages
        var cumulativePages = 0
        
        while toYearMonthDayString(targetDate) <= toYearMonthDayString(currentReadingBook.book.targetEndDate) {
            let dateKey = toYearMonthDayString(targetDate)
            if !currentReadingBook.book.nonReadingDays.map({ toYearMonthDayString($0) }).contains(dateKey) {
                cumulativePages += pagesPerDay
                print("🐲🐲🐲: \(dateKey)")
                currentReadingBook.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        var remainderTargetDate = currentReadingBook.book.targetEndDate
        while remainderOffset > 0 {
            let dateKey = toYearMonthDayString(remainderTargetDate)
            guard var record = currentReadingBook.readingRecords[dateKey] else { return }
            record.targetPages += remainderOffset
            currentReadingBook.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainderTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainderTargetDate)!
        }
    }
    
    // 독서를 해야하는 일수 구하기
    private func calculateTotalReadingDays(for currentReadingBook: UserBook) -> Int {
        var totalDays = 0
        var targetDate = currentReadingBook.book.startDate
        while toYearMonthDayString(targetDate) <= toYearMonthDayString(currentReadingBook.book.targetEndDate) {
            let dateKey = toYearMonthDayString(targetDate)
            if !currentReadingBook.book.nonReadingDays.map({ toYearMonthDayString($0) }).contains(dateKey) {
                totalDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        return totalDays
    }
    
    // 하루에 몇 페이지 읽는지 계산
    func calculatePagesPerDay(for currentReadingBook: UserBook) -> Int {
        let totalReadingDays = calculateTotalReadingDays(for: currentReadingBook)
        return currentReadingBook.book.totalPages / totalReadingDays
    }
    
    // 하루에 몇 페이지 읽는지 계산하고 딱 떨어지지 않는 페이지 수 구하는 메서드
    func calculateRemainderPages(for currentReadingBook: UserBook) -> Int {
        let totalReadingDays = calculateTotalReadingDays(for: currentReadingBook)
        return currentReadingBook.book.totalPages % totalReadingDays
    }
    
    // 읽은 페이지 입력 메서드 (오늘 날짜에만 값을 넣을 수 있음)
    func updateReadingProgress(for currentReadingBook: UserBook, pagesRead: Int, from today: Date) {
        let dateKey = toYearMonthDayString(today)
        guard var record = currentReadingBook.readingRecords[dateKey] else { return }
        
        record.pagesRead = pagesRead
        currentReadingBook.readingRecords[dateKey] = record
        if record.pagesRead != record.targetPages {
            record.targetPages = record.pagesRead
            currentReadingBook.readingRecords[dateKey] = record
            adjustFutureTargets(for: currentReadingBook, from: today)
        }
    }
    
    // 더 읽거나, 덜 읽으면 이후 날짜의 할당량을 다시 계산한다.
    private func adjustFutureTargets(for currentReadingBook: UserBook, from date: Date) {
        let totalRemainingPages = calculateRemainingPages(for: currentReadingBook, from: date)
        let remainingDays = calculateRemainingReadingDays(for: currentReadingBook, from: date)
        guard remainingDays > 0 else { return }
        
        let pagesPerDay = totalRemainingPages / remainingDays
        var remainderOffset = totalRemainingPages % remainingDays
        var cumulativePages = currentReadingBook.readingRecords[toYearMonthDayString(date)]?.pagesRead ?? 0
        
        var nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while toYearMonthDayString(nextDate) <= toYearMonthDayString(currentReadingBook.book.targetEndDate) {
            let dateKey = toYearMonthDayString(nextDate)
            
            if !currentReadingBook.book.nonReadingDays.map({ toYearMonthDayString($0) }).contains(dateKey) {
                guard var record = currentReadingBook.readingRecords[dateKey] else { return }
                
                cumulativePages += pagesPerDay
                record.targetPages = cumulativePages
                currentReadingBook.readingRecords[dateKey] = record
            }
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
        }
        
        var remainingTargetDate = currentReadingBook.book.targetEndDate
        while remainderOffset > 0 {
            let dateKey = toYearMonthDayString(remainingTargetDate)
            
            guard var record = currentReadingBook.readingRecords[dateKey] else { return }
            
            record.targetPages += remainderOffset
            currentReadingBook.readingRecords[dateKey] = record
            remainderOffset -= 1
            
            remainingTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainingTargetDate)!
        }
    }
    
    // 지금까지 읽은 페이지를 제외하고 남은 페이지 계산
    private func calculateRemainingPages(for currentReadingBook: UserBook, from date: Date) -> Int {
        let dateKey = toYearMonthDayString(date)
        guard let record = currentReadingBook.readingRecords[dateKey] else { return 0 }
        
        return currentReadingBook.book.totalPages - record.pagesRead
    }
    
    // 완독까지 남은 기간을 구하는 메서드
    private func calculateRemainingReadingDays(for currentReadingBook: UserBook, from date: Date) -> Int {
        var remainingDays = 0
        var targetDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while toYearMonthDayString(targetDate) <= toYearMonthDayString(currentReadingBook.book.targetEndDate) {
            let dateKey = toYearMonthDayString(targetDate)
            if !currentReadingBook.book.nonReadingDays.map({ toYearMonthDayString($0) }).contains(dateKey) {
                remainingDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        return remainingDays
    }
    
    // 특정 날의 묙표량과 실제 읽은 페이지의 수를 가져오는 메서드
    func getReadingRecord(for currentReadingBook: UserBook, for date: Date) -> ReadingRecord? {
        let dateKey = toYearMonthDayString(date)
        print("💵💵💵💵: \(dateKey)")
        return currentReadingBook.readingRecords[dateKey]
    }
}
