//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct ReadingRecord {
    var targetPages: Int   // 목표로 설정된 페이지 수
    var pagesRead: Int     // 실제 읽은 페이지 수
}

// TODO: 기간이 페이지보다 긴 경우 예외 처리하기 (기간이 너무 길다고 표현)
// TODO: 중간에 목표를 넘으면 중단시키기
// TODO: dailyTargets도 책과 함께 로컬에 저장해야 하는 것 생각
// TODO: 완독 날짜 변경하는 상황 고려

final class ReadingScheduleCalculator: ObservableObject {
    let bookInfo: BookDetails
    @Published var dailyTargets: [String: ReadingRecord] = [:] // 날짜를 문자열로 변환하여 키로 사용
    
    init(bookInfo: BookDetails) {
        self.bookInfo = bookInfo
        calculateInitialDailyTargets() // 초기 목표 계산20
    }
    
    // 날짜를 문자열로 변환하는 유틸리티 함수
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // 초기 목표 설정
    private func calculateInitialDailyTargets() {
        let totalReadingDays = calculateTotalReadingDays()
        let pagesPerDay = bookInfo.totalPages / totalReadingDays
        let remainderPages = bookInfo.totalPages % totalReadingDays
        var targetDate = bookInfo.startDate
        
        var remainderOffset = remainderPages
        
        var cumulativePages = 0 // 누적 합을 추적하는 변수
        
        while formattedDate(targetDate) <= formattedDate(bookInfo.targetEndDate) {
            let dateKey = formattedDate(targetDate)
            if !bookInfo.nonReadingDays.map({ formattedDate($0) }).contains(dateKey) {
                cumulativePages += pagesPerDay // 누적 합에 하루 할당량 추가
                dailyTargets[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 뒤에서부터 남은 페이지 추가해서 계산하기
        var remainderTargetDate = bookInfo.targetEndDate
        while remainderOffset > 0 {
            let dateKey = formattedDate(remainderTargetDate)
            
            guard var record = dailyTargets[dateKey] else { return }
            
            record.targetPages += remainderOffset
            dailyTargets[dateKey] = record
            
            remainderOffset -= 1
            
            remainderTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainderTargetDate)!
        }
    }
    
    // 시작일부터 끝일까지의 날짜 중 읽지 않는 날을 제외한 날 계산
    private func calculateTotalReadingDays() -> Int {
        var totalDays = 0
        var targetDate = bookInfo.startDate
        
        while formattedDate(targetDate) <= formattedDate(bookInfo.targetEndDate) {
            let dateKey = formattedDate(targetDate)
            
            if !bookInfo.nonReadingDays.map({ formattedDate($0) }).contains(dateKey) {
                totalDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        return totalDays
    }
    
    func updateReadingProgress(for date: Date, pagesRead: Int) {
        let dateKey = formattedDate(date)
        
        guard var record = dailyTargets[dateKey] else { return }
        record.pagesRead = pagesRead
        dailyTargets[dateKey] = record
        
        if record.pagesRead != record.targetPages {
            record.targetPages = record.pagesRead
            dailyTargets[dateKey] = record
            
            adjustFutureTargets(from: date)
        }
    }

    private func adjustFutureTargets(from date: Date) {
        let totalRemainingPages = calculateRemainingPages(from: date)
        let remainingDays = calculateRemainingReadingDays(from: date)
        guard remainingDays > 0 else { return }
        
        // 기준 날짜의 하루 할당량 및 남은 페이지 나머지 설정
        let pagesPerDay = totalRemainingPages / remainingDays
        var remainderOffset = totalRemainingPages % remainingDays
        
        var cumulativePages = dailyTargets[formattedDate(date)]?.pagesRead ?? 0
        
        // 미래 날짜들의 목표 페이지 누적 설정
        var nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while formattedDate(nextDate) <= formattedDate(bookInfo.targetEndDate) {
            let dateKey = formattedDate(nextDate)
            
            if !bookInfo.nonReadingDays.map({ formattedDate($0) }).contains(dateKey) {
                guard var record = dailyTargets[dateKey] else { return }
                
                cumulativePages += pagesPerDay // 누적 합에 하루 할당량 추가
                record.targetPages = cumulativePages
                dailyTargets[dateKey] = record
            }
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
        }
        
        // 뒤에서부터 남은 페이지 더하기
        var remainingTargetDate = bookInfo.targetEndDate
        while remainderOffset > 0 {
            let dateKey = formattedDate(remainingTargetDate)
            
            guard var record = dailyTargets[dateKey] else { return }
            
            record.targetPages += remainderOffset
            dailyTargets[dateKey] = record
            remainderOffset -= 1

            remainingTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainingTargetDate)!
        }

    }
    
    private func calculateRemainingPages(from date: Date) -> Int {
        let dateKey = formattedDate(date)
        guard let record = dailyTargets[dateKey] else { return 0 }
        
        return bookInfo.totalPages - record.pagesRead
    }
    
    private func calculateRemainingReadingDays(from date: Date) -> Int {
        var remainingDays = 0
        var targetDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while formattedDate(targetDate) <= formattedDate(bookInfo.targetEndDate) {
            let dateKey = formattedDate(targetDate)
            if !bookInfo.nonReadingDays.map({ formattedDate($0) }).contains(dateKey) {
                remainingDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        return remainingDays
    }
    
    func readingRecord(for date: Date) -> ReadingRecord? {
        let dateKey = formattedDate(date)
        return dailyTargets[dateKey]
    }
}
