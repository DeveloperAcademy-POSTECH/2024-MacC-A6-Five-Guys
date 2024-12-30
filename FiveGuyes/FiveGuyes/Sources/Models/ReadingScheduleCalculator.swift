//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct ReadingScheduleCalculator {
    
    private let readingPagesCalculator: ReadingPagesCalculator = ReadingPagesCalculator()
    private let readingDateCalculator: ReadingDateCalculator = ReadingDateCalculator()
    
    /// 첫날을 기준으로 읽어야하는 페이지를 할당하는 메서드 (초기 페이지 계산)
    func calculateInitialDailyTargets<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress
    ) {
        // TODO: !!!!!!!!!
        let totalDays = try! readingDateCalculator.calculateValidReadingDays(startDate: settings.startDate, endDate: settings.targetEndDate, excludedDates: settings.nonReadingDays)
        
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: totalDays,
            startPage: settings.startPage,
            endPage: settings.targetEndPage)
        
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
            
            targetDate = targetDate.addDays(1)
        }
        
        // 남은 페이지를 뒤에서부터 할당
        var remainderTargetDate = settings.targetEndDate
        while remainderOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(remainderTargetDate)
            guard var record = progress.readingRecords[dateKey] else { return }
            record.targetPages += remainderOffset
            progress.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainderTargetDate = remainderTargetDate.addingDays(-1)
        }
    }
    
    ///  읽은 페이지 입력 메서드 (오늘 날짜에만 값을 넣을 수 있음)
    func updateReadingProgress<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress,
        pagesRead: Int,
        from today: Date
    ) {
        let dateKey = progress.getAdjustedReadingRecordsKey(today)
        
        // 시작날짜보다 오늘 날짜가 이전이면
        if settings.startDate > today {
            settings.changeStartDate(for: today)
        }
        
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
        
        progress.lastPagesRead = pagesRead
        progress.lastReadDate = today.adjustedDate()
        
        // 목표량과 실제 읽은 페이지 수가 다르면 이후 날짜 조정
        if record.pagesRead != record.targetPages {
            progress.readingRecords[dateKey]?.targetPages = record.pagesRead
            adjustFutureTargets(for: settings, progress: progress, from: today)
        }
    }
    
    /// 하루 할당량보다 더 읽거나, 덜 읽으면 이후 날짜의 할당량을 다시 계산한다.
    func adjustFutureTargets<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress,
        from date: Date
    ) {
        // TODO: !!!!!!!!!
        let totalDays = try! readingDateCalculator.calculateValidReadingDays(startDate: date.adjustedDate().addDays(1), endDate: settings.targetEndDate, excludedDates: settings.nonReadingDays)
        
        // 오늘을 남은 일자에서 제외하기 위해 startDate에 1일 추가해서 계산하기
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: totalDays,
            startPage: progress.lastPagesRead,
            endPage: settings.targetEndPage)
        
        var remainderOffset = remainderPages
        var cumulativePages = progress.lastPagesRead
        var nextDate = date.addingDays(1)
        
        while progress.getAdjustedReadingRecordsKey(nextDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getAdjustedReadingRecordsKey(nextDate)
            
            if !settings.nonReadingDays
                .map({ progress.getReadingRecordsKey($0) })
                .contains(dateKey) {
                guard var record = progress.readingRecords[dateKey] else {
                    nextDate = nextDate.addingDays(1)
                    continue
                }
                cumulativePages += pagesPerDay
                record.targetPages = cumulativePages
                progress.readingRecords[dateKey] = record
            }
            nextDate = nextDate.addingDays(1)
        }
        
        var remainingTargetDate = settings.targetEndDate
        while remainderOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(remainingTargetDate)
            guard var record = progress.readingRecords[dateKey] else {
                remainingTargetDate = remainingTargetDate.addingDays(-1)
                continue
            }
            record.targetPages += remainderOffset
            progress.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainingTargetDate = remainingTargetDate.addingDays(-1)
        }
    }
    
    /// 지난 날의 할당량을 읽지 않고, 앱에 새롭게 접속할 때 페이지를 재할당해주는 메서드
    func reassignPagesFromLastReadDate<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) {
        // 이미 오늘 읽은 페이지가 기록되었으면 재분배를 수행하지 않음
        if hasReadPagesAdjustedToday(progress: progress) { return }
        
        var targetDate = Date().adjustedDate()
        
        // TODO: !!!!!!!!!
        let totalDays = try! readingDateCalculator.calculateValidReadingDays(startDate: targetDate, endDate: settings.targetEndDate, excludedDates: settings.nonReadingDays)
        
        // 남은 페이지와 일수를 기준으로 새롭게 할당량 계산 🐯🐯🐯🐯
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: totalDays,
            startPage: progress.lastPagesRead,
            endPage: settings.targetEndPage)
        
        var remainderOffset = remainderPages
        // TODO: ReadingProgress의 lastPagesRead가 디폴트 1로 되어 있어서 우선 여기에 필요 로직 추가
        var cumulativePages = progress.lastPagesRead == 1 ? 0 : progress.lastPagesRead
 
        // 비독서일을 제외하고 할당량 재설정
        while progress.getAdjustedReadingRecordsKey(targetDate) <= progress.getReadingRecordsKey(settings.targetEndDate) {
            let dateKey = progress.getAdjustedReadingRecordsKey(targetDate)
            
            if !settings.nonReadingDays
                .map({ progress.getReadingRecordsKey($0) })
                .contains(dateKey) {
                cumulativePages += pagesPerDay
                progress.readingRecords[dateKey] = ReadingRecord(targetPages: cumulativePages, pagesRead: 0)
            }
            targetDate = targetDate.addingDays(1)
        }
        
        // 남은 페이지를 뒤에서부터 분배
        var remainingTargetDate = settings.targetEndDate
        while remainderOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(remainingTargetDate)
            guard var record = progress.readingRecords[dateKey] else {
                remainingTargetDate = remainingTargetDate.addingDays(-1)
                continue
            }
            
            record.targetPages += remainderOffset
            progress.readingRecords[dateKey] = record
            remainderOffset -= 1
            remainingTargetDate = remainingTargetDate.addingDays(-1)
        }
    }
    
    /// 오늘 할당량이 읽혔는지 확인하는 메서드
    private func hasReadPagesAdjustedToday<Progress: ReadingProgressProtocol>(progress: Progress) -> Bool {
        let today = Date()
        let todayKey = progress.getAdjustedReadingRecordsKey(today)
        return progress.readingRecords[todayKey]?.pagesRead != 0
    }
}

extension ReadingScheduleCalculator {
    /// 기록된 날짜의 수를 계산하는 메서드
    func calculateRecordedDays<Progress: ReadingProgressProtocol>(
        progress: Progress
    ) -> Int {
        return progress.readingRecords.values.filter { $0.pagesRead > 0 }.count
    }
}
