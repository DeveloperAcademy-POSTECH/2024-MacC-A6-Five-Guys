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
        return formatter.string(from: date)
    }
    
    // MARK: 첫날을 기준으로 읽어야하는 페이지를 할당하는 메서드 (초기 페이지 계산)
    func calculateInitialDailyTargets(for currentReadingBook: UserBook) {
        let pagesPerDay = firstCalculatePagesPerDay(for: currentReadingBook)
        let remainderPages = firstCalculateRemainderPages(for: currentReadingBook)
        
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
        
        // 남은 책 분량은 뒤에서부터 1페이지씩 추가합니다.
        var remainderTargetDate = currentReadingBook.book.targetEndDate
        while remainderOffset > 0 {
            let dateKey = toYearMonthDayString(remainderTargetDate)
            guard var record = currentReadingBook.readingRecords[dateKey] else { return }
            record.targetPages += remainderOffset
            currentReadingBook.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainderTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainderTargetDate)!
        }
        
        // 초기화 시 읽은 페이지 관련 데이터 초기 설정
        currentReadingBook.lastReadDate = nil
        currentReadingBook.lastPagesRead = 0
    }
    
    // MARK: 읽은 페이지 입력 메서드 (오늘 날짜에만 값을 넣을 수 있음)
    func updateReadingProgress(for currentReadingBook: UserBook, pagesRead: Int, from today: Date) {
        let dateKey = toYearMonthDayString(today)
        guard var record = currentReadingBook.readingRecords[dateKey] else { return }
        
        record.pagesRead = pagesRead
        currentReadingBook.readingRecords[dateKey] = record
        
        // lastReadDate와 lastPagesRead를 최신화
            currentReadingBook.lastReadDate = today
            currentReadingBook.lastPagesRead = pagesRead
        
        // 목표량과 실제 읽은 페이지 수가 다른 경우 이후 할당량 재조정
        if record.pagesRead != record.targetPages {
            record.targetPages = record.pagesRead
            currentReadingBook.readingRecords[dateKey] = record
            // 이후 날짜의 할당량을 다시 계산한다.
            adjustFutureTargets(for: currentReadingBook, from: today)
        }
    }
    
    //MARK: 더 읽거나, 덜 읽으면 이후 날짜의 할당량을 다시 계산한다.
    func adjustFutureTargets(for currentReadingBook: UserBook, from date: Date) {
        let totalRemainingPages = calculateRemainingPages(for: currentReadingBook)
        print("❌: \(totalRemainingPages)")
        // 오늘 읽었고, 다음 날부터 할당량을 다시 계산하니까 오늘 일 수는 빼고 계산
        let remainingDays = calculateRemainingReadingDays(for: currentReadingBook) - 1
        print("🐶: \(remainingDays)")
        guard remainingDays > 0 else { return }
        
        let pagesPerDay = totalRemainingPages / remainingDays
        var remainderOffset = totalRemainingPages % remainingDays
        var cumulativePages = currentReadingBook.lastPagesRead // 마지막 읽은 페이지를 누적 시작점으로 사용
        
        var nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while toYearMonthDayString(nextDate) <= toYearMonthDayString(currentReadingBook.book.targetEndDate) {
            let dateKey = toYearMonthDayString(nextDate)
            
            if !currentReadingBook.book.nonReadingDays.map({ toYearMonthDayString($0) }).contains(dateKey) {
                guard var record = currentReadingBook.readingRecords[dateKey] else { return }
                
                cumulativePages += pagesPerDay
                record.targetPages = cumulativePages
                print("🙉🙉🙉: \(cumulativePages)")
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
    
    // 이전 할당량을 읽지 않고 새롭게 들어왔을 때 재할당을 위한 메서드
    func reassignPagesFromLastReadDate(for currentReadingBook: UserBook) {
        // 몇 페이지 남음?
        let totalRemainingPages = calculateRemainingPages(for: currentReadingBook)
        
        // 오늘부터 며칠 남음?
        let remainingDays = calculateRemainingReadingDays(for: currentReadingBook)
        
        // 남은 페이지와 날짜를 기준으로 새롭게 할당량 계산
        let pagesPerDay = totalRemainingPages / remainingDays
        var remainderOffset = totalRemainingPages % remainingDays
        var cumulativePages = currentReadingBook.lastPagesRead
        
        var targetDate = Date() // 오늘 날짜부터 새로 할당 시작
        
        while toYearMonthDayString(targetDate) <= toYearMonthDayString(currentReadingBook.book.targetEndDate) {
            let dateKey = toYearMonthDayString(targetDate)
            
            // 비독서일이 아니면 할당량을 새로 설정
            if !currentReadingBook.book.nonReadingDays.map({ toYearMonthDayString($0) }).contains(dateKey) {
                cumulativePages += pagesPerDay
                currentReadingBook.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 나머지 페이지를 마지막 며칠에 배분
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
    
    // MARK: - 초기에 페이지를 할당할 때 필요한 메서드
    // 독서를 해야하는 일수 구하기
    func firstCalculateTotalReadingDays(for currentReadingBook: UserBook) -> Int {
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
    func firstCalculatePagesPerDay(for currentReadingBook: UserBook) -> Int {
        let totalReadingDays = firstCalculateTotalReadingDays(for: currentReadingBook)
        return currentReadingBook.book.totalPages / totalReadingDays
    }
    
    
    // 하루에 몇 페이지 읽는지 계산하고 딱 떨어지지 않는 페이지 수 구하는 메서드
    func firstCalculateRemainderPages(for currentReadingBook: UserBook) -> Int {
        let totalReadingDays = firstCalculateTotalReadingDays(for: currentReadingBook)
        return currentReadingBook.book.totalPages % totalReadingDays
    }
    
    // MARK: - 남은 양을 다시 계산할 때 사용하는 메서드
    // 지금까지 읽은 페이지를 제외하고 남은 페이지 계산
    private func calculateRemainingPages(for currentReadingBook: UserBook) -> Int {
        return currentReadingBook.book.totalPages - currentReadingBook.lastPagesRead
    }
    
    // 완독까지 남은 기간을 구하는 메서드 (오늘부터)
    func calculateRemainingReadingDays(for currentReadingBook: UserBook) -> Int {
        var remainingDays = 0
        var targetDate = Date()
        
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

