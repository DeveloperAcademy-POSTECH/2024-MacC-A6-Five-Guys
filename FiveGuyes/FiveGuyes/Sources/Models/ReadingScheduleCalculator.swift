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
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: settings.startDate,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: settings.startPage,
            endPage: settings.targetEndPage
        )
        
        var targetDate = settings.startDate
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
        distributeRemainingPagesFromEnd(
            progress: progress,
            remainderPages: remainderPages,
            targetEndDate: settings.targetEndDate)
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
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: date.adjustedDate().addDays(1),
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays)
        
        // 오늘을 남은 일자에서 제외하기 위해 startDate에 1일 추가해서 계산하기
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: progress.lastPagesRead,
            endPage: settings.targetEndPage)
        
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
        
        // 남은 페이지를 뒤에서부터 할당
        distributeRemainingPagesFromEnd(
            progress: progress,
            remainderPages: remainderPages,
            targetEndDate: settings.targetEndDate
        )
    }
    
    
    
    /// 지난 날의 할당량을 읽지 않고, 앱에 새롭게 접속할 때 페이지를 재할당해주는 메서드
    func reassignPagesFromLastReadDate<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) {
        // 이미 오늘 읽은 페이지가 기록되었으면 재분배를 수행하지 않음
        if hasReadPagesAdjustedToday(progress: progress) { return }
        
        var targetDate = Date().adjustedDate()
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: targetDate,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        // 남은 페이지와 일수를 기준으로 새롭게 할당량 계산 🐯🐯🐯🐯
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: progress.lastPagesRead,
            endPage: settings.targetEndPage)
        
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
        
        // 남은 페이지를 뒤에서부터 할당
        distributeRemainingPagesFromEnd(
            progress: progress,
            remainderPages: remainderPages,
            targetEndDate: settings.targetEndDate)
    }
    
    private func getRemainingReadingDays(startDate: Date, targetEndDate: Date, nonReadingDays: [Date]) -> Int {
        do {
            return try readingDateCalculator.calculateValidReadingDays(
                startDate: startDate,
                endDate: targetEndDate,
                excludedDates: nonReadingDays
            )
        } catch {
            fatalError("getRemainingReadingDays: \(error)")
        }
    }
    
    /// 마지막 날부터 남은 페이지를 역순으로 분배하는 메서드
    /// - Parameters:
    ///   - progress: 읽기 기록 데이터를 포함한 Progress 객체.
    ///   - remainderPages: 분배해야 할 남은 페이지 수.
    ///   - targetEndDate: 읽기 일정의 마지막 날짜.
    private func distributeRemainingPagesFromEnd<Progress: ReadingProgressProtocol>(
        progress: Progress,
        remainderPages: Int,
        targetEndDate: Date
    ) {
        var remainingOffset = remainderPages
        var currentTargetDate = targetEndDate
        
        // 마지막 날짜부터 시작하여 남은 페이지를 분배
        while remainingOffset > 0 {
            let dateKey = progress.getReadingRecordsKey(currentTargetDate)
            
            // 현재 날짜에 해당하는 기록이 없으면 이전 날짜로 이동
            guard var record = progress.readingRecords[dateKey] else {
                currentTargetDate = currentTargetDate.addingDays(-1)
                continue
            }
            
            // 현재 날짜의 목표 페이지에 남은 페이지를 추가
            record.targetPages += remainingOffset
            progress.readingRecords[dateKey] = record
            
            // 남은 페이지 수를 감소시키고 이전 날짜로 이동
            remainingOffset -= 1
            currentTargetDate = currentTargetDate.addingDays(-1)
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
