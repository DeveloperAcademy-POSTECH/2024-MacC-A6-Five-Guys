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

    // 날짜 계산은 이 도구에게 맡깁니다.
    // 본 계산기가 날짜 계산까지 다 하면 코드가 복잡해져서 실수하기 쉬워집니다.
    private let dateMath: DateMathCalculator
    // 페이지 나누기 계산은 이 도구가 담당합니다.
    // 나중에 계산이 틀렸을 때 어느 부분이 문제인지 바로 찾기 쉽습니다.
    private let pageMath: PageMathCalculator

    // MARK: - Initialization

    // 필요한 값을 밖에서 받아 시작할 수 있게 만든 생성자입니다.
    // 이렇게 해야 프리뷰/테스트에서 원하는 상황을 정확히 다시 만들 수 있습니다.
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
    // 책을 처음 등록할 때, 날짜별 목표 페이지표를 처음 만드는 함수입니다.
    // 이 표가 이후 모든 진행 계산의 출발점이 됩니다.
    func createInitialSchedule(
        settings: FGUserSetting
    ) throws -> FGReadingProgress {
        do {
            // 1. 시작일부터 종료일까지의 스케줄 생성
            // 계산된 결과를 날짜별 기록으로 묶어 둡니다.
            // 이렇게 묶어야 화면과 저장소가 같은 데이터를 읽을 수 있습니다.
            let records = try makeScheduleSegment(
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
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
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
    // 오늘 읽은 값을 기록하고, 필요하면 남은 날의 목표를 다시 계산합니다.
    // 이 과정을 거쳐야 계획과 실제 읽은 양이 계속 맞춰집니다.
    func applyTodayReading(
        settings: FGUserSetting,
        progress: FGReadingProgress,
        pagesRead: Int,
        date: Date
    ) throws -> (progress: FGReadingProgress, updatedSettings: FGUserSetting?) {
        let key = date.toYearMonthDayString()
        // 기존 기록을 바로 덮어쓰지 않고, 먼저 이 임시 변수에서 안전하게 수정합니다.
        // 중간에 계산이 실패해도 원본 상태를 잃지 않게 하려는 장치입니다.
        var newRecords = progress.dailyReadingRecords

        // 1. 오늘 날짜에 읽은 페이지 기록
        let currentRecord = newRecords[key] ?? ReadingRecord(targetPages: 0, pagesRead: 0)
        newRecords[key] = ReadingRecord(
            targetPages: currentRecord.targetPages,
            pagesRead: pagesRead
        )

        // 2. 제외일 처리: 해당 날짜가 제외일이었다면 목록에서 제거
        // 오늘이 쉬는 날 목록에 있으면, 그 목록을 갱신한 새 설정을 만듭니다.
        // 이 값을 따로 들고 있어야 이후 재계산에서 최신 규칙을 쓸 수 있습니다.
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
        // 방금 계산한 결과를 담아 새 진행 상태를 만듭니다.
        // 이 값을 저장하고 화면에 돌려줘야 사용자에게 같은 결과가 보입니다.
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

        // 오늘 실제 읽은 양이 계획과 달라지면, 남은 날 목표를 다시 맞춰야 합니다.
        // 이 분기에서 그 재계산 흐름으로 이동합니다.
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
    // 특정 날짜 다음부터 목표를 다시 나눠서 남은 계획을 바로잡는 함수입니다.
    // 과거 기록은 지키고, 미래 계획만 안전하게 고칩니다.
    func adjustFutureTargets(
        settings: FGUserSetting,
        progress: FGReadingProgress,
        fromDate: Date
    ) throws -> FGReadingProgress {
        do {
            // 1. 다음날부터 재계산 시작
            let nextDay = fromDate.addDays(1)

            // 2. 다음날부터 종료일까지의 새 스케줄 생성
            // 다시 계산한 구간만 따로 뽑아 둡니다.
            // 이 중간 값을 써야 기존 기록과 새 기록을 섞지 않고 정확히 합칠 수 있습니다.
            let newSegment = try makeScheduleSegment(
                settings: settings,
                startDate: nextDay,
                startPageExclusive: progress.lastReadPage  // 현재까지 읽은 페이지
            )

            // 3. 기존 progress와 병합 (fromDate 이후만 교체)
            // 기존 기록과 새 구간을 합쳐 최종 결과를 만듭니다.
            // 이 단계가 빠지면 화면/저장소가 서로 다른 데이터를 보게 됩니다.
            let mergedProgress = mergeProgress(
                base: progress,
                replacingFrom: nextDay,
                with: newSegment
            )

            return mergedProgress
        } catch let error as DateMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
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
    // 앱을 다시 열었을 때 계획을 다시 맞춰야 하는지 확인하는 함수입니다.
    // 이 검사가 없으면 오래된 목표가 그대로 남아 사용자에게 잘못 보일 수 있습니다.
    func rescheduleOnAppOpen(
        settings: FGUserSetting,
        progress: FGReadingProgress,
        today: Date
    ) throws -> FGReadingProgress {
        // 1. 목표 종료일이 지났는지 확인
        if today.toYearMonthDayString() > settings.targetEndDate.toYearMonthDayString() {
            // 목표 종료일이 이미 지났다면 일반 재계산을 하면 안 됩니다.
            // 이 경우를 따로 던져서, 위 단계에서 안내 문구를 정확히 보여주게 합니다.
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
            // 다시 계산한 구간만 따로 뽑아 둡니다.
            // 이 중간 값을 써야 기존 기록과 새 기록을 섞지 않고 정확히 합칠 수 있습니다.
            let newSegment = try makeScheduleSegment(
                settings: settings,
                startDate: today,
                startPageExclusive: progress.lastReadPage  // 마지막까지 읽은 페이지
            )

            // 5. 기존 progress와 병합 (today 이후만 교체)
            // 기존 기록과 새 구간을 합쳐 최종 결과를 만듭니다.
            // 이 단계가 빠지면 화면/저장소가 서로 다른 데이터를 보게 됩니다.
            let mergedProgress = mergeProgress(
                base: progress,
                replacingFrom: today,
                with: newSegment
            )

            return mergedProgress
        } catch let error as DateMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
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
    // 사용자가 기간/제외일을 바꿨을 때 전체 계획을 다시 맞추는 함수입니다.
    // 옛 기록을 그대로 쓰면 새 규칙과 충돌하므로 먼저 정리 후 다시 계산합니다.
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
        // 새 설정 범위를 벗어난 기록은 먼저 치워 둡니다.
        // 입력을 깨끗하게 맞춘 뒤 계산해야 결과가 흔들리지 않습니다.
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
            // 다시 계산한 구간만 따로 뽑아 둡니다.
            // 이 중간 값을 써야 기존 기록과 새 기록을 섞지 않고 정확히 합칠 수 있습니다.
            let newSegment = try makeScheduleSegment(
                settings: newSettings,
                startDate: today,
                startPageExclusive: cleanedBase.lastReadPage
            )

            // 5. 기존 progress와 병합
            // 기존 기록과 새 구간을 합쳐 최종 결과를 만듭니다.
            // 이 단계가 빠지면 화면/저장소가 서로 다른 데이터를 보게 됩니다.
            let mergedProgress = mergeProgress(
                base: cleanedBase,
                replacingFrom: today,
                with: newSegment
            )

            return mergedProgress
        } catch let error as DateMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
            throw ScheduleCalculationError.calculationFailed(underlying: error)
        } catch let error as PageMathCalculator.MathError {
            // 여기서는 이 오류를 고칠 방법이 없어서 위로 그대로 넘깁니다.
            // 위 단계에서 사용자 안내나 재시도 정책을 결정하게 합니다.
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
    // 시작일에서 종료일까지 하루 목표표를 만드는 내부 함수입니다.
    // 같은 계산 규칙을 여러 메서드에서 재사용하려고 분리해 두었습니다.
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
        // 계산된 결과를 날짜별 기록으로 묶어 둡니다.
        // 이렇게 묶어야 화면과 저장소가 같은 데이터를 읽을 수 있습니다.
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
    // 기존 기록과 새 계산 결과를 날짜 기준으로 합치는 함수입니다.
    // 합치는 기준이 흔들리면 과거 기록이 사라지거나 중복될 수 있습니다.
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
    // 재계산 전에 필요 없는 기록을 먼저 정리합니다.
    // 이 단계가 있어야 계산 입력이 단순해지고, 예외 케이스가 줄어듭니다.
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
