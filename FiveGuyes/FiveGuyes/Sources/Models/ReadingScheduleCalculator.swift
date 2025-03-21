//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

enum ReadingScheduleError: Error {
    case targetDatePassed
}

/// 독서 스케줄을 계산하고 관리하는 구조체
struct ReadingScheduleCalculator {
    private let readingPagesCalculator: ReadingPagesCalculator = ReadingPagesCalculator()
    private let readingDateCalculator: ReadingDateCalculator = ReadingDateCalculator()
    
    /// 첫날을 기준으로 읽어야하는 페이지를 할당하는 메서드 (초기 페이지 계산)
    func calculateInitialDailyTargets<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress
    ) {
        let readingStartDate = settings.startDate
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: readingStartDate,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: settings.startPage,
            endPage: settings.targetEndPage
        )
        
        // 페이지 분배 계산
        calculateReadingPages(
            for: progress,
            startingPage: progress.lastPagesRead,
            pagesPerDay: pagesPerDay,
            remainderPages: remainderPages,
            startDate: readingStartDate,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        // 목표 종료 페이지와 마지막 날 할당 페이지를 검증 및 수정
        adjustLastDayTargetPage(
            progress: progress,
            targetEndDate: settings.targetEndDate,
            targetEndPage: settings.targetEndPage
        )
    }
    
    ///  읽은 페이지 입력 메서드 (오늘 날짜에만 값을 넣을 수 있음)
    func updateReadingProgress<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress,
        pagesRead: Int,
        from today: Date
    ) {
        let adjustedDateKey = progress.getAdjustedReadingRecordsKey(today)
        
        // 시작날짜보다 오늘 날짜가 이전이면
        if settings.startDate > today {
            settings.changeStartDate(for: today)
        }
        
        var record = progress.readingRecords[adjustedDateKey, default: ReadingRecord(targetPages: 0, pagesRead: 0)]
        
        // 비독서일에서 해당 날짜 제거
        if let index = settings.nonReadingDays.firstIndex(where: {
            progress.getReadingRecordsKey($0) == adjustedDateKey
        }) {
            settings.nonReadingDays.remove(at: index)
        }
        
        // 페이지 읽기 업데이트
        record.pagesRead = pagesRead
        progress.readingRecords[adjustedDateKey] = record
        
        progress.lastPagesRead = pagesRead
        progress.lastReadDate = today.adjustedDate()
        
        // 목표량과 실제 읽은 페이지 수가 다르면 이후 날짜 조정
        if record.pagesRead != record.targetPages {
            progress.readingRecords[adjustedDateKey]?.targetPages = record.pagesRead
            adjustFutureTargets(for: settings, progress: progress, from: today)
        }
    }
    
    /// 하루 할당량보다 더 읽거나, 덜 읽으면 이후 날짜의 할당량을 다시 계산한다.
    func adjustFutureTargets<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress,
        from date: Date
    ) {
        // 다음날을 기준으로 새롭게 페이지를 분배하기 위해 date에 1일을 추가해서 계산합니다.
        let startDate = date.adjustedDate().addDays(1)
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: startDate,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays)
        
        let (pagesPerDay, remainderPages) = readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: progress.lastPagesRead + 1, // 시작 페이지 == 이전까지 읽은 페이지 + 1
            endPage: settings.targetEndPage
        )
        
        // 페이지 분배 계산
        calculateReadingPages(
            for: progress,
            startingPage: progress.lastPagesRead,
            pagesPerDay: pagesPerDay,
            remainderPages: remainderPages,
            startDate: startDate,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        // 목표 종료 페이지와 마지막 날 할당 페이지를 검증 및 수정
        adjustLastDayTargetPage(
            progress: progress,
            targetEndDate: settings.targetEndDate,
            targetEndPage: settings.targetEndPage
        )
    }
    
    /// 지난 날의 할당량을 읽지 않고, 앱에 새롭게 접속할 때 페이지를 재할당해주는 메서드
    func reassignPagesFromLastReadDate<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) throws {
        let adjustedToday = Date().adjustedDate()
        
        // 완독 날짜가 지나면 에러 처리
        if adjustedToday.onlyDate > settings.targetEndDate.onlyDate {
            throw ReadingScheduleError.targetDatePassed
        }
        
        // 이미 오늘 읽은 페이지가 기록되었으면 재분배를 수행하지 않음
        if hasReadPagesAdjustedToday(progress: progress) {
            print("페이지 재분배1 ❌❌❌ ")
            return
        }
        
        // TODO: 독서 시작 날짜와 조정된 오늘 날짜가 같은 날에는 재할당 막기
        // 불필요한 계산
        if settings.startDate.toYearMonthDayString() == adjustedToday.toYearMonthDayString() {
            print("페이지 재분배2 ❌❌❌ ")
            return
        }
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: adjustedToday,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        // 남은 페이지와 일수를 기준으로 새롭게 할당량 계산 🐯🐯🐯🐯
        let (pagesPerDay, remainderPages) =
        readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: progress.lastPagesRead,
            endPage: settings.targetEndPage
        )
        
        // 페이지 분배 계산
        calculateReadingPages(
            for: progress,
            startingPage: progress.lastPagesRead,
            pagesPerDay: pagesPerDay,
            remainderPages: remainderPages,
            startDate: adjustedToday,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        // 목표 종료 페이지와 마지막 날 할당 페이지를 검증 및 수정
        adjustLastDayTargetPage(
            progress: progress,
            targetEndDate: settings.targetEndDate,
            targetEndPage: settings.targetEndPage
        )
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
    
    /// 읽기 페이지를 계산하고 목표를 설정하는 메서드
    /// - Parameters:
    ///   - progress: 읽기 기록 데이터를 포함한 Progress 객체.
    ///   - startingPage: 시작 페이지 (처음 읽는 경우 0).
    ///   - pagesPerDay: 하루에 할당할 페이지 수.
    ///   - remainderPages: 뒤에서 분배해야 할 남은 페이지 수.
    ///   - startDate: 읽기를 시작할 날짜.
    ///   - targetEndDate: 읽기를 종료할 목표 날짜.
    ///   - nonReadingDays: 비독서일의 날짜 배열.
    private func calculateReadingPages<Progress: ReadingProgressProtocol>(
        for progress: Progress,
        startingPage: Int,
        pagesPerDay: Int,
        remainderPages: Int,
        startDate: Date,
        targetEndDate: Date,
        nonReadingDays: [Date]
    ) {
        // 앞에서부터 하루 할당량을 계산하고 기록 업데이트
        assignPagesForEachDay(
            for: progress,
            startingPage: startingPage,
            pagesPerDay: pagesPerDay,
            startDate: startDate,
            targetEndDate: targetEndDate,
            nonReadingDays: nonReadingDays
        )
        
        // 뒤에서부터 남은 페이지를 분배
        distributeRemainderPagesBackward(
            progress: progress,
            remainderPages: remainderPages,
            targetEndDate: targetEndDate
        )
    }
    
    /// 읽기 기록을 업데이트하는 메서드
    /// - Parameters:
    ///   - progress: 읽기 기록 데이터를 포함한 Progress 객체.
    ///   - startingPage: 이전에 마지막으로 읽은 페이지. 처음 읽는 경우 0으로 설정해야 합니다.
    ///   - pagesPerDay: 하루에 할당할 페이지 수.
    ///   - startDate: 읽기를 시작할 날짜.
    ///   - targetEndDate: 읽기를 종료할 목표 날짜.
    ///   - nonReadingDays: 비독서일의 날짜 배열.
    private func assignPagesForEachDay<Progress: ReadingProgressProtocol>(
        for progress: Progress,
        startingPage: Int,
        pagesPerDay: Int,
        startDate: Date,
        targetEndDate: Date,
        nonReadingDays: [Date]
    ) {
        var cumulativePages = startingPage
        var targetDate = startDate
        
        // 비독서일을 키로 변환하여 비교용 배열 생성
        let nonReadingDaysKey = nonReadingDays.map { progress.getReadingRecordsKey($0) }
        
        // 시작 날짜부터 목표 날짜까지 반복
        while progress.getReadingRecordsKey(targetDate) <= progress.getReadingRecordsKey(targetEndDate) {
            let dateKey = progress.getReadingRecordsKey(targetDate)
            
            // 비독서일이 아닌 경우에만 기록을 업데이트
            if !nonReadingDaysKey.contains(dateKey) {
                cumulativePages += pagesPerDay
                progress.readingRecords[dateKey, default: ReadingRecord(targetPages: cumulativePages, pagesRead: 0)].targetPages = cumulativePages
            }
            
            // 다음 날짜로 이동
            targetDate = targetDate.addDays(1)
        }
    }
    
    /// 마지막 날부터 남은 페이지를 역순으로 분배하는 메서드
    /// - Parameters:
    ///   - progress: 읽기 기록 데이터를 포함한 Progress 객체.
    ///   - remainderPages: 분배해야 할 남은 페이지 수.
    ///   - targetEndDate: 읽기 일정의 마지막 날짜.
    private func distributeRemainderPagesBackward<Progress: ReadingProgressProtocol>(
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
        let adjustedTodayKey = progress.getAdjustedReadingRecordsKey(today)
        
        // 해당 날짜에 기록이 없는 경우
        guard let record = progress.readingRecords[adjustedTodayKey] else { return false }
        
        return record.pagesRead != 0
    }
}

extension ReadingScheduleCalculator {
    /// 기록된 날짜의 수를 계산하는 메서드
    func calculateRecordedDays<Progress: ReadingProgressProtocol>(
        progress: Progress
    ) -> Int {
        return progress.readingRecords.values.filter { $0.pagesRead > 0 }.count
    }
    
    /// 마지막 날 할당 페이지를 목표 페이지로 재조정하는 메서드
    /// - Parameters:
    ///   - progress: 독서 진행 상황 객체
    ///   - targetEndDate: 목표 종료 날짜
    ///   - targetEndPage: 목표 종료 페이지
    private func adjustLastDayTargetPage<Progress: ReadingProgressProtocol>(
        progress: Progress,
        targetEndDate: Date,
        targetEndPage: Int
    ) {
        let endDateKey = progress.getReadingRecordsKey(targetEndDate)
        if progress.readingRecords[endDateKey]?.targetPages != targetEndPage {
            progress.readingRecords[endDateKey]?.targetPages = targetEndPage
        }
    }
}

// MARK: - 독서 날짜가 변경되면 업데이트
extension ReadingScheduleCalculator {
    /// 독서 일정이 변경된 경우 페이지를 재할당하는 메서드
    func reassignPagesForUpdatedDates<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        settings: Settings,
        progress: Progress
    ) {
        let adjustedToday = Date().adjustedDate()
        
        if settings.startDate.toKoreanDateString() >= adjustedToday.toKoreanDateString() {
            // 시작 날짜가 변경된 경우
            progress.readingRecords = [:]
            calculateInitialDailyTargets(for: settings, progress: progress)
            return
        }
        
        // 데이터 정리 로직 호출
        cleanUpInvalidRecords(for: settings, progress: progress)
        
        // 이미 오늘 읽은 페이지가 기록되었으면 다음날부터 재분배
        if hasReadPagesAdjustedToday(progress: progress) {
            adjustFutureTargets(for: settings, progress: progress, from: Date())
            return
        }
        
        let remainingReadingDays = getRemainingReadingDays(
            startDate: adjustedToday,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        // 남은 페이지와 일수를 기준으로 새롭게 할당량 계산 🐯🐯🐯🐯
        let (pagesPerDay, remainderPages) =
        readingPagesCalculator.calculatePagesPerDayAndRemainder(
            totalDays: remainingReadingDays,
            startPage: progress.lastPagesRead,
            endPage: settings.targetEndPage
        )
        
        // 페이지 분배 계산
        calculateReadingPages(
            for: progress,
            startingPage: progress.lastPagesRead,
            pagesPerDay: pagesPerDay,
            remainderPages: remainderPages,
            startDate: adjustedToday,
            targetEndDate: settings.targetEndDate,
            nonReadingDays: settings.nonReadingDays
        )
        
        // 목표 종료 페이지와 마지막 날 할당 페이지를 검증 및 수정
        adjustLastDayTargetPage(
            progress: progress,
            targetEndDate: settings.targetEndDate,
            targetEndPage: settings.targetEndPage
        )
    }
    
    /// 불필요한 읽기 기록 데이터를 제거하는 메서드
    private func cleanUpInvalidRecords<Settings: UserSettingsProtocol, Progress: ReadingProgressProtocol>(
        for settings: Settings,
        progress: Progress
    ) {
        // 시작 날짜 이전 및 마지막 날짜 이후 데이터를 필터링
        let filteredRecords = filteredProgressForDateRange(
            progress: progress,
            startDate: settings.startDate,
            endDate: settings.targetEndDate
        )
        progress.readingRecords = filteredRecords
        // 제외된 날짜 데이터를 필터링
        let filteredExcludedDates = filteredProgressForExcludedDates(
            progress: progress,
            excludedDates: settings.nonReadingDays
        )
        progress.readingRecords = filteredExcludedDates
    }
    
    /// 목표의 마지막 날짜 이후 및 시작 날짜 이전에 저장된 읽기 기록 데이터를 제거합니다.
    /// - Returns: 지정된 범위를 벗어난 데이터를 제거한 읽기 기록.
    private func filteredProgressForDateRange<Progress: ReadingProgressProtocol>(
        progress: Progress,
        startDate: Date,
        endDate: Date
    ) -> [String: ReadingRecord] {
        let adjustedStartDateKey = progress.getReadingRecordsKey(startDate)
        let adjustedEndDateKey = progress.getReadingRecordsKey(endDate)
        
        // 시작 날짜 이전 또는 마지막 날짜 이후 데이터를 제거한 결과 반환
        return progress.readingRecords.filter { record in
            record.key >= adjustedStartDateKey && record.key <= adjustedEndDateKey
        }
    }
    
    /// 제외된 날짜를 기준으로 필터링된 읽기 기록 데이터를 반환합니다.
    /// - Returns: 제외된 날짜를 제거한 읽기 기록.
    private func filteredProgressForExcludedDates<Progress: ReadingProgressProtocol>(
        progress: Progress,
        excludedDates: [Date]
    ) -> [String: ReadingRecord] {
        let excludedDateKeys = excludedDates.map { progress.getReadingRecordsKey($0) }
        
        // 제외된 날짜를 제거한 결과 반환
        return progress.readingRecords.filter { record in
            !excludedDateKeys.contains(record.key)
        }
    }
}
