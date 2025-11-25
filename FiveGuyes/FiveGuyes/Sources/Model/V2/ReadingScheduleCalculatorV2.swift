//
//  ReadingScheduleCalculatorV2.swift
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

// MARK: - ReadingScheduleCalculatorV2

/// 독서 스케줄을 계산하는 Pure Function 기반 Calculator (V2)
struct ReadingScheduleCalculatorV2 {

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

    /// 1. 초기 스케줄 생성
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
        settings: FGUserSetting
    ) throws -> FGReadingProgress {
        do {
            // 1. 시작일부터 종료일까지의 스케줄 생성
            var records = try makeScheduleSegment(
                settings: settings,
                startDate: settings.startDate,
                startPageExclusive: settings.startPage - 1  // 시작 페이지 이전
            )

            // 2. 새로운 FGReadingProgress 반환
            return FGReadingProgress(
                dailyReadingRecords: records,
                lastReadDate: nil,  // 아직 독서 시작 전
                lastReadPage: settings.startPage - 1  // 시작 페이지 이전
            )
        } catch let error as DateMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        }
    }

    /// 2. 오늘 읽기 반영
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
        date: Date
    ) throws -> (progress: FGReadingProgress, updatedSettings: FGUserSetting?) {
        let key = date.toYearMonthDayString()
        var newRecords = progress.dailyReadingRecords

        // 1. 오늘 날짜에 읽은 페이지 기록
        let currentRecord = newRecords[key] ?? ReadingRecord(targetPages: 0, pagesRead: 0)
        newRecords[key] = ReadingRecord(
            targetPages: currentRecord.targetPages,
            pagesRead: pagesRead
        )

        // 2. 제외일 처리: 해당 날짜가 제외일이었다면 목록에서 제거
        var updatedSettings: FGUserSetting?
        let excludedKey = settings.excludedReadingDays.first(where: { $0.toYearMonthDayString() == key })
        if excludedKey != nil {
            let newExcludedDays = settings.excludedReadingDays.filter { $0.toYearMonthDayString() != key }
            updatedSettings = FGUserSetting(
                startPage: settings.startPage,
                targetEndPage: settings.targetEndPage,
                startDate: settings.startDate,
                targetEndDate: settings.targetEndDate,
                excludedReadingDays: newExcludedDays
            )
        }

        // 3. 업데이트된 progress 생성
        let updatedProgress = FGReadingProgress(
            dailyReadingRecords: newRecords,
            lastReadDate: date,
            lastReadPage: pagesRead
        )

        // 4. 재조정이 필요한 경우 확인
        // - 제외일이 변경된 경우: 유효 일수가 변경되므로 재조정 필요
        // - 목표와 실제가 다른 경우: 남은 페이지가 변경되므로 재조정 필요
        let needsRecalculation =
            updatedSettings != nil ||  // 제외일 변경
            (currentRecord.targetPages != 0 && pagesRead != currentRecord.targetPages)  // 목표 불일치

        if needsRecalculation {
            // 목표를 실제 읽은 페이지로 변경
            newRecords[key] = ReadingRecord(targetPages: pagesRead, pagesRead: pagesRead)

            // 다음날부터 재조정 (제외일이 변경되었다면 새 설정 사용)
            let adjustedSettings = updatedSettings ?? settings

            let recalculatedProgress = try adjustFutureTargets(
                settings: adjustedSettings,
                progress: FGReadingProgress(
                    dailyReadingRecords: newRecords,
                    lastReadDate: date,
                    lastReadPage: pagesRead
                ),
                fromDate: date
            )

            return (progress: recalculatedProgress, updatedSettings: updatedSettings)
        }

        // 5. 재조정 불필요하면 그냥 반환
        return (progress: updatedProgress, updatedSettings: updatedSettings)
    }

    /// 3. 미래 목표 재조정
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
        fromDate: Date
    ) throws -> FGReadingProgress {
        do {
            // 1. 다음날부터 재계산 시작
            let nextDay = fromDate.addDays(1)

            // 2. 다음날부터 종료일까지의 새 스케줄 생성
            var newSegment = try makeScheduleSegment(
                settings: settings,
                startDate: nextDay,
                startPageExclusive: progress.lastReadPage  // 현재까지 읽은 페이지
            )

            // 3. 기존 progress와 병합 (fromDate 이후만 교체)
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

    /// 4. 앱 재접속 시 재분배
    ///
    /// 사용자가 며칠간 독서하지 않고 앱에 재접속했을 때,
    /// 오늘부터 목표일까지 남은 페이지를 재분배합니다.
    ///
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
        today: Date
    ) throws -> FGReadingProgress {
        // 1. 목표 종료일이 지났는지 확인
        if today.toYearMonthDayString() > settings.targetEndDate.toYearMonthDayString() {
            throw ScheduleCalculationError.targetDatePassed
        }

        // 2. 오늘 이미 읽은 기록이 있으면 재분배하지 않음
        let todayKey = today.toYearMonthDayString()
        if let todayRecord = progress.dailyReadingRecords[todayKey],
           todayRecord.pagesRead > 0 {
            return progress  // 변경 없음
        }

        // 3. 시작일이 오늘 이후면 재분배하지 않음 (아직 시작 전)
        if settings.startDate.toYearMonthDayString() >= today.toYearMonthDayString() {
            return progress  // 변경 없음
        }

        do {
            // 4. 오늘부터 종료일까지의 새 스케줄 생성
            var newSegment = try makeScheduleSegment(
                settings: settings,
                startDate: today,
                startPageExclusive: progress.lastReadPage  // 마지막까지 읽은 페이지
            )

            // 5. 기존 progress와 병합 (today 이후만 교체)
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

    /// 5. 설정 변경 시 재분배
    ///
    /// 사용자가 독서 설정(시작일, 종료일, 제외일)을 변경했을 때
    /// 스케줄을 재계산합니다.
    ///
    /// - Parameters:
    ///   - oldSettings: 이전 설정
    ///   - newSettings: 새로운 설정
    ///   - progress: 현재 독서 진행 상황
    ///   - today: 오늘 날짜 (이미 보정 완료)
    /// - Returns: 설정 변경이 반영된 FGReadingProgress
    /// - Throws:
    ///   - `ScheduleCalculationError.calculationFailed`: 재분배 실패
    func rescheduleForSettingsChange(
        oldSettings: FGUserSetting,
        newSettings: FGUserSetting,
        progress: FGReadingProgress,
        today: Date
    ) throws -> FGReadingProgress {
        // 1. 시작일이 미래로 변경된 경우 → 전체 재계산
        if newSettings.startDate.toYearMonthDayString() >= today.toYearMonthDayString() {
            return try createInitialSchedule(settings: newSettings)
        }

        // 2. 기존 기록 정리 (변경된 범위/제외일에 따라)
        let cleanedBase = cleanedProgress(progress: progress, settings: newSettings)

        // 3. 오늘 이미 읽은 기록이 있으면 다음날부터 재분배
        let todayKey = today.toYearMonthDayString()
        if let todayRecord = cleanedBase.dailyReadingRecords[todayKey],
           todayRecord.pagesRead > 0 {
            return try adjustFutureTargets(
                settings: newSettings,
                progress: cleanedBase,
                fromDate: today
            )
        }

        // 4. 오늘부터 재분배
        do {
            var newSegment = try makeScheduleSegment(
                settings: newSettings,
                startDate: today,
                startPageExclusive: cleanedBase.lastReadPage
            )

            // 5. 기존 progress와 병합
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

    /// 특정 날짜부터 종료일까지의 일일 목표 스케줄 세그먼트를 생성합니다.
    ///
    /// - Parameters:
    ///   - settings: 독서 설정
    ///   - startDate: 스케줄 시작 날짜
    ///   - startPageExclusive: 시작 페이지 (이전까지 읽은 페이지)
    /// - Returns: 날짜 키와 ReadingRecord의 Dictionary
    /// - Throws: 날짜/페이지 계산 에러
    private func makeScheduleSegment(
        settings: FGUserSetting,
        startDate: Date,
        startPageExclusive: Int
    ) throws -> [String: ReadingRecord] {
        // 1. 유효 독서 일수 계산 (제외일 제외)
        let validDays = try dateMath.validDays(
            from: startDate,
            to: settings.targetEndDate,
            excluding: settings.excludedReadingDays
        )

        // 2. 읽어야 할 페이지 범위 계산
        let startPage = startPageExclusive + 1  // 다음 페이지부터 시작
        let endPage = settings.targetEndPage

        // 3. 일일 페이지 수와 나머지 계산
        let divisionResult = try pageMath.dividePages(
            from: startPage,
            to: endPage,
            over: validDays
        )

        // 4. 유효 일자 수만큼 "일일 분배량 배열" 준비
        //    - 앞쪽 (validDays - remainder)일 → daily
        //    - 뒤쪽 remainder일 → daily + 1
        var pagesPerValidDay: [Int] = []
        pagesPerValidDay.reserveCapacity(validDays)

        let extraStartIndex = validDays - divisionResult.remainder
        for index in 0..<validDays {
            let isExtraDay = index >= extraStartIndex
            let pagesForDay = divisionResult.daily + (isExtraDay ? 1 : 0)
            pagesPerValidDay.append(pagesForDay)
        }

        // 5. 날짜를 순회하며 제외일이 아닌 날에만 pagesPerValidDay를 소비
        var records: [String: ReadingRecord] = [:]
        var cumulativePages = startPageExclusive
        var currentDate = startDate
        let excludedKeys = Set(settings.excludedReadingDays.map { $0.toYearMonthDayString() })
        var validDayIndex = 0

        let endKey = settings.targetEndDate.toYearMonthDayString()

        while currentDate.toYearMonthDayString() <= endKey,
              validDayIndex < pagesPerValidDay.count {
            let key = currentDate.toYearMonthDayString()

            if !excludedKeys.contains(key) {
                let pagesForDay = pagesPerValidDay[validDayIndex]
                cumulativePages += pagesForDay

                records[key] = ReadingRecord(
                    targetPages: cumulativePages,
                    pagesRead: 0
                )

                validDayIndex += 1
            }

            currentDate = currentDate.addDays(1)
        }

        return records
    }

    /// 기존 progress에 새로운 스케줄 세그먼트를 병합합니다.
    ///
    /// - Parameters:
    ///   - base: 기존 독서 진행 상황
    ///   - replacingDate: 교체 시작 날짜
    ///   - segment: 새로운 스케줄 세그먼트
    /// - Returns: 병합된 FGReadingProgress
    private func mergeProgress(
        base: FGReadingProgress,
        replacingFrom replacingDate: Date,
        with segment: [String: ReadingRecord]
    ) -> FGReadingProgress {
        var mergedRecords = base.dailyReadingRecords
        let replacingKey = replacingDate.toYearMonthDayString()

        // replacingDate 이후의 기존 기록 제거
        mergedRecords = mergedRecords.filter { key, _ in
            key < replacingKey
        }

        // 새 segment 병합
        for (key, record) in segment {
            mergedRecords[key] = record
        }

        return FGReadingProgress(
            dailyReadingRecords: mergedRecords,
            lastReadDate: base.lastReadDate,
            lastReadPage: base.lastReadPage
        )
    }

    /// 불필요한 독서 기록을 정리합니다.
    ///
    /// **정리 대상:**
    /// - 시작일 이전 날짜의 기록
    /// - 종료일 이후 날짜의 기록
    /// - 제외일에 해당하는 기록
    ///
    /// - Parameters:
    ///   - progress: 정리할 독서 진행 상황
    ///   - settings: 독서 설정
    /// - Returns: 정리된 FGReadingProgress
    private func cleanedProgress(
        progress: FGReadingProgress,
        settings: FGUserSetting
    ) -> FGReadingProgress {
        let startKey = settings.startDate.toYearMonthDayString()
        let endKey = settings.targetEndDate.toYearMonthDayString()
        let excludedKeys = Set(settings.excludedReadingDays.map { $0.toYearMonthDayString() })

        // 범위 내 + 제외일 아닌 기록만 유지
        let cleanedRecords = progress.dailyReadingRecords.filter { key, _ in
            key >= startKey && key <= endKey && !excludedKeys.contains(key)
        }

        return FGReadingProgress(
            dailyReadingRecords: cleanedRecords,
            lastReadDate: progress.lastReadDate,
            lastReadPage: progress.lastReadPage
        )
    }
}
