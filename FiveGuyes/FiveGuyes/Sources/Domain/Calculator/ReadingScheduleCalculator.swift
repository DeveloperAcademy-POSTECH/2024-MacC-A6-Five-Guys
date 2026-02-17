//
//  ReadingScheduleCalculator.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-10-24.
//

import Foundation

// MARK: - Error Types

/// 스케줄 계산 중 발생할 수 있는 에러 타입
enum ScheduleCalculationError: Error {
    /// 목표 종료일이 이미 지난 경우
    case targetDatePassed
    /// 잘못된 날짜 범위 (startDate > endDate)
    case invalidDateRange
    /// 잘못된 페이지 범위 (startPage > endPage 등)
    case invalidPageRange
    /// 하위 Calculator에서 발생한 에러를 래핑
    case calculationFailed(underlying: Error)
}

// MARK: - ReadingScheduleCalculator

/// 독서 스케줄을 계산하는 Pure Function 기반 Calculator
struct ReadingScheduleCalculator {

    // MARK: - Properties

    private let dateMath: DateMathCalculator
    private let pageMath: PageMathCalculator

    // MARK: - Initialization

    init(
        dateMath: DateMathCalculator = DateMathCalculator(),
        pageMath: PageMathCalculator = PageMathCalculator()
    ) {
        self.dateMath = dateMath
        self.pageMath = pageMath
    }

    // MARK: - Public Methods

    /// 초기 스케줄을 생성합니다.
    ///
    /// 독서 시작 시 전체 기간에 대한 일일 목표 페이지를 계산합니다.
    ///
    /// - Parameters:
    ///   - settings: 독서 설정 (시작/종료일, 페이지 범위 등)
    /// - Returns: 일일 목표가 설정된 FGReadingProgress
    /// - Throws:
    ///   - `ScheduleCalculationError.invalidDateRange`: 날짜 범위 오류
    ///   - `ScheduleCalculationError.invalidPageRange`: 페이지 범위 오류
    ///   - `ScheduleCalculationError.calculationFailed`: 계산 실패
    func createInitialSchedule(
        settings: FGUserSetting,
        activeTimeZoneID: String = ReadingRecord.legacyDefaultTimeZoneID
    ) throws -> FGReadingProgress {
        do {
            let records = try makeScheduleSegment(
                settings: settings,
                startDate: settings.startDate,
                startPageExclusive: settings.startPage - 1,
                activeTimeZoneID: activeTimeZoneID
            )

            return FGReadingProgress(
                dailyReadingRecords: records,
                lastReadDate: nil,
                lastReadPage: settings.startPage - 1
            )
        } catch let error as DateMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        }
    }

    /// 오늘 읽기 기록을 반영합니다.
    ///
    /// 사용자가 오늘 읽은 페이지를 기록하고, 필요 시 미래 목표를 재조정합니다.
    ///
    /// **중요:**
    /// - `date`는 이미 `adjustedForDailyBoundary()` 적용된 날짜여야 함
    /// - Calculator 내부에서 날짜 보정하지 않음
    ///
    /// - Parameters:
    ///   - settings: 독서 설정
    ///   - progress: 현재 독서 진행 상황
    ///   - pagesRead: 오늘 읽은 페이지 수
    ///   - date: 기록 날짜 (이미 보정 완료)
    /// - Returns: (progress: 업데이트된 FGReadingProgress, updatedSettings: 설정 변경 시 새 설정)
    /// - Throws:
    ///   - `ScheduleCalculationError.calculationFailed`: 재조정 실패
    func applyTodayReading(
        settings: FGUserSetting,
        progress: FGReadingProgress,
        pagesRead: Int,
        date: Date,
        activeTimeZoneID: String = ReadingRecord.legacyDefaultTimeZoneID
    ) throws -> (progress: FGReadingProgress, updatedSettings: FGUserSetting?) {
        let key = date.readingDateKey
        let isBeforeStartDate = key < settings.startDateKey
        var newRecords = progress.dailyReadingRecords

        let currentRecord = newRecords[key.rawValue] ?? ReadingRecord(targetPages: 0, pagesRead: 0)
        // forward-only 정책: "지금 쓰는 레코드"만 현재 타임존 스냅샷으로 기록한다.
        newRecords[key.rawValue] = ReadingRecord(
            targetPages: currentRecord.targetPages,
            pagesRead: pagesRead,
            timeZoneID: activeTimeZoneID
        )

        var updatedSettings: FGUserSetting?
        let excludedKey = settings.excludedReadingDayKeys.first(where: { $0 == key })
        if excludedKey != nil {
            let newExcludedDayKeys = settings.excludedReadingDayKeys.filter { $0 != key }
            updatedSettings = FGUserSetting(
                startPage: settings.startPage,
                targetEndPage: settings.targetEndPage,
                startDateKey: settings.startDateKey,
                targetEndDateKey: settings.targetEndDateKey,
                excludedReadingDayKeys: newExcludedDayKeys
            )
        }

        let updatedProgress = FGReadingProgress(
            dailyReadingRecords: newRecords,
            lastReadDate: date,
            lastReadPage: pagesRead
        )

        let shouldRecalculate = needsRecalculation(
            hasUpdatedSettings: updatedSettings != nil,
            currentTargetPages: currentRecord.targetPages,
            pagesRead: pagesRead,
            isBeforeStartDate: isBeforeStartDate
        )

        if shouldRecalculate {
            newRecords[key.rawValue] = ReadingRecord(
                targetPages: pagesRead,
                pagesRead: pagesRead,
                timeZoneID: activeTimeZoneID
            )

            let adjustedSettings = updatedSettings ?? settings
            let baseDate = recalculationBaseDate(
                isBeforeStartDate: isBeforeStartDate,
                settings: adjustedSettings,
                recordDate: date
            )

            let recalculatedProgress = try adjustFutureTargets(
                settings: adjustedSettings,
                progress: FGReadingProgress(
                    dailyReadingRecords: newRecords,
                    lastReadDate: date,
                    lastReadPage: pagesRead
                ),
                fromDate: baseDate,
                activeTimeZoneID: activeTimeZoneID
            )

            return (progress: recalculatedProgress, updatedSettings: updatedSettings)
        }

        return (progress: updatedProgress, updatedSettings: updatedSettings)
    }

    /// 미래 목표를 재조정합니다.
    ///
    /// - Parameters:
    ///   - settings: 독서 설정
    ///   - progress: 현재 독서 진행 상황
    ///   - fromDate: 재조정 시작 날짜 (이 날 다음날부터 재계산)
    /// - Returns: 미래 목표가 재조정된 FGReadingProgress
    /// - Throws:
    ///   - `ScheduleCalculationError.calculationFailed`: 재조정 실패
    func adjustFutureTargets(
        settings: FGUserSetting,
        progress: FGReadingProgress,
        fromDate: Date,
        activeTimeZoneID: String = ReadingRecord.legacyDefaultTimeZoneID
    ) throws -> FGReadingProgress {
        do {
            let nextDay = fromDate.addDays(1)

            let newSegment = try makeScheduleSegment(
                settings: settings,
                startDate: nextDay,
                startPageExclusive: progress.lastReadPage,
                activeTimeZoneID: activeTimeZoneID
            )

            let mergedProgress = mergeProgress(
                base: progress,
                replacingFrom: nextDay,
                with: newSegment
            )

            return mergedProgress
        } catch let error as DateMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        }
    }

    /// 앱 재접속 시 목표를 재분배합니다.
    /// - Parameters:
    ///   - settings: 독서 설정
    ///   - progress: 현재 독서 진행 상황
    ///   - today: 오늘 날짜 (이미 보정 완료)
    /// - Returns: 재분배된 FGReadingProgress
    /// - Throws:
    ///   - `ScheduleCalculationError.targetDatePassed`: 목표일 지남
    ///   - `ScheduleCalculationError.calculationFailed`: 재분배 실패
    func rescheduleOnAppOpen(
        settings: FGUserSetting,
        progress: FGReadingProgress,
        today: Date,
        activeTimeZoneID: String = ReadingRecord.legacyDefaultTimeZoneID
    ) throws -> FGReadingProgress {
        if today.readingDateKey > settings.targetEndDateKey {
            throw ScheduleCalculationError.targetDatePassed
        }

        let todayKey = today.readingDateKey
        if let todayRecord = progress.dailyReadingRecords[todayKey.rawValue],
           todayRecord.pagesRead > 0 {
            return progress
        }

        if settings.startDateKey >= today.readingDateKey {
            return progress
        }

        do {
            let newSegment = try makeScheduleSegment(
                settings: settings,
                startDate: today,
                startPageExclusive: progress.lastReadPage,
                activeTimeZoneID: activeTimeZoneID
            )

            let mergedProgress = mergeProgress(
                base: progress,
                replacingFrom: today,
                with: newSegment
            )

            return mergedProgress
        } catch let error as DateMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        }
    }

    /// 설정 변경 후 목표를 재분배합니다.
    /// - Parameters:
    ///   - newSettings: 새로운 설정
    ///   - progress: 현재 독서 진행 상황
    ///   - today: 오늘 날짜 (이미 보정 완료)
    /// - Returns: 설정 변경이 반영된 FGReadingProgress
    /// - Throws:
    ///   - `ScheduleCalculationError.calculationFailed`: 재분배 실패
    func rescheduleForSettingsChange(
        newSettings: FGUserSetting,
        progress: FGReadingProgress,
        today: Date,
        activeTimeZoneID: String = ReadingRecord.legacyDefaultTimeZoneID
    ) throws -> FGReadingProgress {
        if newSettings.startDateKey >= today.readingDateKey {
            return try createInitialSchedule(
                settings: newSettings,
                activeTimeZoneID: activeTimeZoneID
            )
        }

        let cleanedBase = cleanedProgress(progress: progress, settings: newSettings)

        let todayKey = today.readingDateKey
        if let todayRecord = cleanedBase.dailyReadingRecords[todayKey.rawValue],
           todayRecord.pagesRead > 0 {
            return try adjustFutureTargets(
                settings: newSettings,
                progress: cleanedBase,
                fromDate: today,
                activeTimeZoneID: activeTimeZoneID
            )
        }

        do {
            let newSegment = try makeScheduleSegment(
                settings: newSettings,
                startDate: today,
                startPageExclusive: cleanedBase.lastReadPage,
                activeTimeZoneID: activeTimeZoneID
            )

            let mergedProgress = mergeProgress(
                base: cleanedBase,
                replacingFrom: today,
                with: newSegment
            )

            return mergedProgress
        } catch let error as DateMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        }
    }

    // MARK: - Private Helper Methods

    private func needsRecalculation(
        hasUpdatedSettings: Bool,
        currentTargetPages: Int,
        pagesRead: Int,
        isBeforeStartDate: Bool
    ) -> Bool {
        hasUpdatedSettings ||
            (currentTargetPages != 0 && pagesRead != currentTargetPages) ||
            (isBeforeStartDate && pagesRead > 0)
    }

    private func recalculationBaseDate(
        isBeforeStartDate: Bool,
        settings: FGUserSetting,
        recordDate: Date
    ) -> Date {
        isBeforeStartDate ? settings.startDate.addDays(-1) : recordDate
    }

    private func makeScheduleSegment(
        settings: FGUserSetting,
        startDate: Date,
        startPageExclusive: Int,
        activeTimeZoneID: String
    ) throws -> [String: ReadingRecord] {
        let validDays = try dateMath.validDays(
            from: startDate,
            to: settings.targetEndDate,
            excluding: settings.excludedReadingDays
        )

        let startPage = startPageExclusive + 1
        let endPage = settings.targetEndPage

        let divisionResult = try pageMath.dividePages(
            from: startPage,
            to: endPage,
            over: validDays
        )

        var pagesPerValidDay: [Int] = []
        pagesPerValidDay.reserveCapacity(validDays)

        let extraStartIndex = validDays - divisionResult.remainder
        for index in 0..<validDays {
            let isExtraDay = index >= extraStartIndex
            let pagesForDay = divisionResult.daily + (isExtraDay ? 1 : 0)
            pagesPerValidDay.append(pagesForDay)
        }

        var records: [String: ReadingRecord] = [:]
        var cumulativePages = startPageExclusive
        var currentDate = startDate
        let excludedKeys = Set(settings.excludedReadingDayKeys)
        var validDayIndex = 0

        let endKey = settings.targetEndDateKey

        while currentDate.readingDateKey <= endKey,
              validDayIndex < pagesPerValidDay.count {
            let key = currentDate.readingDateKey

            if !excludedKeys.contains(key) {
                let pagesForDay = pagesPerValidDay[validDayIndex]
                cumulativePages += pagesForDay

                records[key.rawValue] = ReadingRecord(
                    targetPages: cumulativePages,
                    pagesRead: 0,
                    timeZoneID: activeTimeZoneID
                )

                validDayIndex += 1
            }

            currentDate = currentDate.addDays(1)
        }

        return records
    }

    private func mergeProgress(
        base: FGReadingProgress,
        replacingFrom replacingDate: Date,
        with segment: [String: ReadingRecord]
    ) -> FGReadingProgress {
        var mergedRecords = base.dailyReadingRecords
        let replacingKey = replacingDate.readingDateKey

        mergedRecords = mergedRecords.filter { key, _ in
            ReadingDateKey.fromStoredKey(key) < replacingKey
        }

        for (key, record) in segment {
            mergedRecords[key] = record
        }

        return FGReadingProgress(
            dailyReadingRecords: mergedRecords,
            lastReadDate: base.lastReadDate,
            lastReadPage: base.lastReadPage
        )
    }

    private func cleanedProgress(
        progress: FGReadingProgress,
        settings: FGUserSetting
    ) -> FGReadingProgress {
        let startKey = settings.startDateKey
        let endKey = settings.targetEndDateKey
        let excludedKeys = Set(settings.excludedReadingDayKeys)

        let cleanedRecords = progress.dailyReadingRecords.filter { key, _ in
            let readingDateKey = ReadingDateKey.fromStoredKey(key)
            return readingDateKey >= startKey
                && readingDateKey <= endKey
                && !excludedKeys.contains(readingDateKey)
        }

        return FGReadingProgress(
            dailyReadingRecords: cleanedRecords,
            lastReadDate: progress.lastReadDate,
            lastReadPage: progress.lastReadPage
        )
    }
}
