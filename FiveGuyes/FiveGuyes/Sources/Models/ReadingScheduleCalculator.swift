//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct ReadingScheduleCalculator {
    
    /// 첫날을 기준으로 읽어야하는 페이지를 할당하는 메서드 (초기 페이지 계산)
    func calculateInitialDailyTargets<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress
    ) {
        let (pagesPerDay, remainderPages) = firstCalculatePagesPerDay(settings: settings, progress: progress)
        
        var targetDate = settings.startDate
        var remainderOffset = remainderPages
        var cumulativePages = 0
        
        // 비독서일을 제외하고 읽어야 할 페이지를 초기 할당
        while progress.getReadingRecordsKey(targetDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getReadingRecordsKey(targetDate)
            
            if !settings.nonReadingDays.map({ progress.getReadingRecordsKey($0) }).contains(dateKey) {
                cumulativePages += pagesPerDay
                progress.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 남은 페이지를 뒤에서부터 할당
        var remainderTargetDate = settings.targetEndDate
        while remainderOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(remainderTargetDate)
            guard var record = progress.readingRecords[dateKey] else { return }
            record.targetPages += 1
            progress.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainderTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainderTargetDate)!
        }
        
        // 초기화 시 읽은 페이지 관련 데이터 초기 설정
        progress.lastReadDate = nil
        progress.lastPagesRead = 0
    }
    
    ///  읽은 페이지 입력 메서드 (오늘 날짜에만 값을 넣을 수 있음)
    func updateReadingProgress<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress,
        pagesRead: Int,
        from today: Date
    ) {
        let dateKey = progress.getAdjustedReadingRecordsKey(today)
        
        var record = progress.readingRecords[dateKey, default: ReadingRecord(targetPages: 0, pagesRead: 0)]
        
        // 비독서일에서 해당 날짜 제거
        if let index = settings.nonReadingDays.firstIndex(where: {
            progress.getReadingRecordsKey($0) == dateKey
        }) {
            settings.nonReadingDays.remove(at: index)
        }
        
        // 페이지 읽기 업데이트
        record.pagesRead = pagesRead
        progress.readingRecords[dateKey] = record
        
        // 목표량과 실제 읽은 페이지 수가 다르면 이후 날짜 조정
        if record.pagesRead != record.targetPages {
            adjustFutureTargets(for: settings, progress: progress, from: today)
        }
    }
    
    /// 하루 할당량보다 더 읽거나, 덜 읽으면 이후 날짜의 할당량을 다시 계산한다.
    func adjustFutureTargets<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress,
        from date: Date
    ) {
        let totalRemainingPages = calculateRemainingPages(settings: settings, progress: progress)
        // 오늘을 남은 일자에서 제외하기 위해 각각 메서드 사용
        let remainingDays = calculateRemainingReadingDays(settings: settings, progress: progress) - 1
        
        guard remainingDays > 0 else { return }
        
        let pagesPerDay = totalRemainingPages / remainingDays
        var remainderOffset = totalRemainingPages % remainingDays
        var cumulativePages = progress.lastPagesRead
        
        var nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        
        while progress.getAdjustedReadingRecordsKey(nextDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getAdjustedReadingRecordsKey(nextDate)
            
            if !settings.nonReadingDays
                .map({ progress.getReadingRecordsKey($0) })
                .contains(dateKey) {
                guard var record = progress.readingRecords[dateKey] else { return }
                cumulativePages += pagesPerDay
                record.targetPages = cumulativePages
                progress.readingRecords[dateKey] = record
            }
            
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
        }
        
        var remainingTargetDate = settings.targetEndDate
        while remainderOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(remainingTargetDate)
            
            guard var record = progress.readingRecords[dateKey] else { return }
            record.targetPages += 1
            progress.readingRecords[dateKey] = record
            remainderOffset -= 1
            
            remainingTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainingTargetDate)!
        }
    }
    
    /// 지난 날의 할당량을 읽지 않고, 앱에 새롭게 접속할 때 페이지를 재할당해주는 메서드
    func reassignPagesFromLastReadDate<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) {
        // 이미 오늘 읽은 페이지가 기록되었으면 재분배를 수행하지 않음
        if hasReadPagesAdjustedToday(progress: progress) { return }
        
        // 남은 페이지와 일수를 기준으로 새롭게 할당량 계산
        let (pagesPerDay, remainderPages) = calculatePagesPerDay(settings: settings, progress: progress)
        var remainderOffset = remainderPages
        var cumulativePages = progress.lastPagesRead
        
        var targetDate = Date()
        
        // 비독서일을 제외하고 할당량 재설정
        while progress.getAdjustedReadingRecordsKey(targetDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getAdjustedReadingRecordsKey(targetDate)
            
            if !settings.nonReadingDays
                .map({ progress.getReadingRecordsKey($0) })
                .contains(dateKey) {
                cumulativePages += pagesPerDay
                progress.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        // 남은 페이지를 뒤에서부터 분배
        var remainingTargetDate = settings.targetEndDate
        while remainderOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(remainingTargetDate)
            guard var record = progress.readingRecords[dateKey] else { return }
            
            record.targetPages += 1
            progress.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainingTargetDate = Calendar.current.date(byAdding: .day, value: -1, to: remainingTargetDate)!
        }
    }
    
    
    /// 오늘 할당량이 읽혔는지 확인하는 메서드
    private func hasReadPagesAdjustedToday<Progress: ReadingProgressProtocol>(progress: Progress) -> Bool {
        let today = Date()
        let todayKey = progress.getAdjustedReadingRecordsKey(today)
        return progress.readingRecords[todayKey]?.pagesRead != 0
    }
    
    // MARK: - 초기에 페이지를 할당할 때 필요한 메서드
    // 독서를 해야하는 일수 구하기
    func firstCalculateTotalReadingDays<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) -> Int {
        var totalDays = 0
        var targetDate = settings.startDate
        
        while progress.getReadingRecordsKey(targetDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getReadingRecordsKey(targetDate)
            
            if !settings.nonReadingDays
                .map({ progress.getReadingRecordsKey($0) })
                .contains(dateKey) {
                totalDays += 1
            }
            
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        return totalDays
    }
    
    // 하루에 몇 페이지 읽는지 계산
    func firstCalculatePagesPerDay<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) -> (pagesPerDay: Int, remainder: Int) {
        let totalReadingDays = firstCalculateTotalReadingDays(settings: settings, progress: progress)
        
        // 총 페이지 수와 하루 할당량 계산
        let totalPages = settings.targetEndPage - settings.startPage + 1
        let pagesPerDay = totalPages / totalReadingDays
        let remainder = totalPages % totalReadingDays
        
        return (pagesPerDay, remainder)
    }
    
    // MARK: - 남은 양을 다시 계산할 때 사용하는 메서드
    // 지금까지 읽은 페이지를 제외하고 남은 페이지 계산
    func calculateRemainingPages<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) -> Int {
        return settings.targetEndPage - progress.lastPagesRead
    }
    
    /// 완독까지 남은 기간을 구하는 메서드 (오늘부터)
    func calculateRemainingReadingDays<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) -> Int {
        var remainingDays = 0
        var targetDate = Date()
        
        while progress.getAdjustedReadingRecordsKey(targetDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getAdjustedReadingRecordsKey(targetDate)
            if !settings.nonReadingDays
                .map({ progress.getReadingRecordsKey($0) })
                .contains(dateKey) {
                remainingDays += 1
            }
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        return remainingDays
    }
    
    ///  하루에 몇 페이지를 읽어야 하는지를 구하는 메서드
    func calculatePagesPerDay<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) -> (pagesPerDay: Int, remainder: Int) {
        let totalRemainingPages = calculateRemainingPages(settings: settings, progress: progress)
        let remainingDays = calculateRemainingReadingDays(settings: settings, progress: progress)
        
        guard remainingDays > 0 else { return (0, 0) } // 남은 날짜가 없으면 0 반환
        
        let pagesPerDay = totalRemainingPages / remainingDays
        let remainder = totalRemainingPages % remainingDays
        
        return (pagesPerDay, remainder)
    }
}
