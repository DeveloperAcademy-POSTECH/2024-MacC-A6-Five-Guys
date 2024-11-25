//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct ReadingScheduleCalculator {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    // MARK: 첫날을 기준으로 읽어야하는 페이지를 할당하는 메서드 (초기 페이지 계산)
    func calculateInitialDailyTargets(for currentReadingBook: UserBook) {
        let (pagesPerDay, remainderPages) = firstCalculatePagesPerDay(for: currentReadingBook)
        
        var targetDate = currentReadingBook.book.startDate
        var remainderOffset = remainderPages
        var cumulativePages = 0
        
        while currentReadingBook.getReadingRecordsKey(targetDate) <= currentReadingBook.getReadingRecordsKey(currentReadingBook.book.targetEndDate) {
            let dateKey = currentReadingBook.getReadingRecordsKey(targetDate)
            if !currentReadingBook.book.nonReadingDays.map({ currentReadingBook.getReadingRecordsKey($0) }).contains(dateKey) {
                cumulativePages += pagesPerDay
                print("🐲🐲🐲: \(dateKey), \(cumulativePages)")
                currentReadingBook.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 남은 책 분량은 뒤에서부터 1페이지씩 추가합니다.
        var remainderTargetDate = currentReadingBook.book.targetEndDate
        while remainderOffset > 0 {
            let dateKey = currentReadingBook.getReadingRecordsKey(remainderTargetDate)
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
    
    ///  읽은 페이지 입력 메서드 (오늘 날짜에만 값을 넣을 수 있음) ⏰
    func updateReadingProgress(for currentReadingBook: UserBook, pagesRead: Int, from today: Date) {
        // ⏰
        let dateKey = currentReadingBook.getAdjustedReadingRecordsKey(today)
        
        // 기록이 없으면 기본값 추가
        var record = currentReadingBook.readingRecords[dateKey, default: ReadingRecord(targetPages: 0, pagesRead: 0)]
        
        // nonReadingDays에서 today 제거 (dateKey로 비교)
        if let index = currentReadingBook.book.nonReadingDays
            .firstIndex(where: { currentReadingBook.getReadingRecordsKey($0) == dateKey }) {
            currentReadingBook.book.nonReadingDays.remove(at: index)
        } else {
            print("지울 날짜 없음 == 이미 할당되어 있는 날입니다.")
        }
        
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
    
    /// 하루 할당량보다 더 읽거나, 덜 읽으면 이후 날짜의 할당량을 다시 계산한다. ⏰
    func adjustFutureTargets(for currentReadingBook: UserBook, from date: Date) {
        let totalRemainingPages = calculateRemainingPages(for: currentReadingBook)
        // 오늘 읽었고, 다음 날부터 할당량을 다시 계산하니까 오늘 일 수는 빼고 계산
        let remainingDays = calculateRemainingReadingDays(for: currentReadingBook) - 1
        guard remainingDays > 0 else { return }
        
        let pagesPerDay = totalRemainingPages / remainingDays
        var remainderOffset = totalRemainingPages % remainingDays
        var cumulativePages = currentReadingBook.lastPagesRead // 마지막 읽은 페이지를 누적 시작점으로 사용
        
        //  ⏰
        var nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while currentReadingBook.getAdjustedReadingRecordsKey(nextDate) <= currentReadingBook.getReadingRecordsKey(currentReadingBook.book.targetEndDate) {
            let dateKey = currentReadingBook.getAdjustedReadingRecordsKey(nextDate)
            
            if !currentReadingBook.book.nonReadingDays
                .map({ currentReadingBook.getReadingRecordsKey($0) })
                .contains(dateKey) {
                guard var record = currentReadingBook.readingRecords[dateKey] else { return }
                cumulativePages += pagesPerDay
                record.targetPages = cumulativePages
                print("🦶: \(dateKey) / \(record)")
                print("🙉🙉🙉: \(cumulativePages)")
                currentReadingBook.readingRecords[dateKey] = record
            }
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
        }
        
        var remainingTargetDate = currentReadingBook.book.targetEndDate
        while remainderOffset > 0 {
            let dateKey = currentReadingBook.getReadingRecordsKey(remainingTargetDate)
            
            guard var record = currentReadingBook.readingRecords[dateKey] else { return }
            
            record.targetPages += remainderOffset
            currentReadingBook.readingRecords[dateKey] = record
            remainderOffset -= 1
            
            remainingTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainingTargetDate)!
        }
    }
    
    /// 지난 날의 할당량을 읽지 않고, 앱에 새롭게 접속할 때 페이지를 재할당해주는 메서드 ⏰
    func reassignPagesFromLastReadDate(for currentReadingBook: UserBook) {
        // 이미 읽었으면 재분배 x
        if hasReadPagesAdjustedToday(for: currentReadingBook) { return }
        
        // 남은 페이지와 일수를 기준으로 새롭게 할당량 계산
        let (pagesPerDay, remainderPages) = calculatePagesPerDay(for: currentReadingBook)
        var remainderOffset = remainderPages
        var cumulativePages = currentReadingBook.lastPagesRead
        
        var targetDate = Date()
        
        while currentReadingBook.getAdjustedReadingRecordsKey(targetDate) <= currentReadingBook.getReadingRecordsKey(currentReadingBook.book.targetEndDate) {
            let dateKey = currentReadingBook.getAdjustedReadingRecordsKey(targetDate)
            
            // 비독서일이 아니면 할당량을 새로 설정
            if !currentReadingBook.book.nonReadingDays
                .map({ currentReadingBook.getReadingRecordsKey($0) })
                .contains(dateKey) {
                cumulativePages += pagesPerDay
                currentReadingBook.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 나머지 페이지를 마지막 며칠에 배분
        var remainingTargetDate = currentReadingBook.book.targetEndDate
        while remainderOffset > 0 {
            let dateKey = currentReadingBook.getReadingRecordsKey(remainingTargetDate)
            guard var record = currentReadingBook.readingRecords[dateKey] else { return }
            
            record.targetPages += remainderOffset
            currentReadingBook.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainingTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainingTargetDate)!
        }
    }
    
    
    /// 오늘 할당량이 읽혔는지 확인하는 메서드 ⏰
    private func hasReadPagesAdjustedToday(for currentReadingBook: UserBook) -> Bool {
        let today = Date()
        let todayKey = currentReadingBook.getAdjustedReadingRecordsKey(today)
        return currentReadingBook.readingRecords[todayKey]?.pagesRead != 0
    }
    
    // MARK: - 초기에 페이지를 할당할 때 필요한 메서드
    // 독서를 해야하는 일수 구하기
    func firstCalculateTotalReadingDays(for currentReadingBook: UserBook) -> Int {
        var totalDays = 0
        var targetDate = currentReadingBook.book.startDate
        
        while currentReadingBook.getReadingRecordsKey(targetDate) <= currentReadingBook.getReadingRecordsKey(currentReadingBook.book.targetEndDate) {
            let dateKey = currentReadingBook.getReadingRecordsKey(targetDate)
            if !currentReadingBook.book.nonReadingDays
                .map({ currentReadingBook.getReadingRecordsKey($0) })
                .contains(dateKey) {
                totalDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        return totalDays
    }
    
    // 하루에 몇 페이지 읽는지 계산
    func firstCalculatePagesPerDay(for currentReadingBook: UserBook) -> (pagesPerDay: Int, remainder: Int) {
        let totalReadingDays = firstCalculateTotalReadingDays(for: currentReadingBook)
        let pagesPerDay = currentReadingBook.book.totalPages / totalReadingDays
        let remainder = currentReadingBook.book.totalPages % totalReadingDays
        
        return (pagesPerDay, remainder)
    }
    
    // MARK: - 남은 양을 다시 계산할 때 사용하는 메서드
    // 지금까지 읽은 페이지를 제외하고 남은 페이지 계산
    private func calculateRemainingPages(for currentReadingBook: UserBook) -> Int {
        return currentReadingBook.book.totalPages - currentReadingBook.lastPagesRead
    }
    
    // 완독까지 남은 기간을 구하는 메서드 (오늘부터) ⏰
    func calculateRemainingReadingDays(for currentReadingBook: UserBook) -> Int {
        var remainingDays = 0
        var targetDate = Date()
        
        while currentReadingBook.getAdjustedReadingRecordsKey(targetDate) <= currentReadingBook.getReadingRecordsKey(currentReadingBook.book.targetEndDate) {
            let dateKey = currentReadingBook.getAdjustedReadingRecordsKey(targetDate)
            
            if !currentReadingBook.book.nonReadingDays
                .map({ currentReadingBook.getReadingRecordsKey($0) })
                .contains(dateKey) {
                remainingDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        return remainingDays
    }
    
    // 남은 페이지와 날짜를 기반으로 일일 할당량을 계산하는 메서드
    func calculatePagesPerDay(for currentReadingBook: UserBook) -> (pagesPerDay: Int, remainder: Int) {
        let totalRemainingPages = calculateRemainingPages(for: currentReadingBook)
        let remainingDays = calculateRemainingReadingDays(for: currentReadingBook)
        
        let pagesPerDay = totalRemainingPages / remainingDays
        let remainder = totalRemainingPages % remainingDays
        
        print("❌읽는 중: \(totalRemainingPages)")
        print("🐶읽는 중: \(remainingDays)")
        
        return (pagesPerDay, remainder)
    }
}
