//
//  ReadingScheduleCalculatorV2Tests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2025-10-24.
//

@testable import FiveGuyes
import Foundation
import Testing

/// ReadingScheduleCalculatorV2에 대한 Swift Testing 기반 테스트
@Suite("ReadingScheduleCalculatorV2 테스트")
struct ReadingScheduleCalculatorV2Tests {

    let calculator = ReadingScheduleCalculatorV2()

    // MARK: - Helper Methods

    /// 테스트용 날짜 생성 헬퍼 (yyyy-MM-dd 형식)
    private func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }

    /// 테스트용 FGUserSetting 생성 헬퍼
    private func makeSettings(
        startPage: Int = 1,
        targetEndPage: Int = 100,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date] = []
    ) -> FGUserSetting {
        return FGUserSetting(
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    /// 테스트용 FGReadingProgress 생성 헬퍼
    private func makeProgress(
        dailyReadingRecords: [String: ReadingRecord] = [:],
        lastReadDate: Date? = nil,
        lastReadPage: Int = 0
    ) -> FGReadingProgress {
        return FGReadingProgress(
            dailyReadingRecords: dailyReadingRecords,
            lastReadDate: lastReadDate,
            lastReadPage: lastReadPage
        )
    }

    // MARK: - Test Fixture Factories

    /// 완전한 초기 스케줄 생성 (createInitialSchedule 호출)
    /// - 실제 앱처럼 모든 유효 날짜에 대한 기록이 생성됨
    private func makeCompleteSchedule(
        startDate: Date,
        endDate: Date,
        startPage: Int = 1,
        targetEndPage: Int = 100,
        excludedDays: [Date] = []
    ) throws -> FGReadingProgress {
        let settings = makeSettings(
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            targetEndDate: endDate,
            excludedReadingDays: excludedDays
        )

        return try calculator.createInitialSchedule(settings: settings)
    }

    /// 특정 날짜에 독서 기록이 있는 완전한 스케줄 생성
    /// - 초기 스케줄을 만든 후 지정된 날짜에 applyTodayReading을 적용
    private func makeProgressWithReadingHistory(
        startDate: Date,
        endDate: Date,
        startPage: Int = 1,
        targetEndPage: Int = 100,
        excludedDays: [Date] = [],
        readDates: [Date: Int] = [:]  // date -> pagesRead
    ) throws -> FGReadingProgress {
        var settings = makeSettings(
            startPage: startPage,
            targetEndPage: targetEndPage,
            startDate: startDate,
            targetEndDate: endDate,
            excludedReadingDays: excludedDays
        )

        var progress = try calculator.createInitialSchedule(settings: settings)

        // 지정된 날짜에 독서 적용
        for (date, pagesRead) in readDates.sorted(by: { $0.key < $1.key }) {
            let result = try calculator.applyTodayReading(
                settings: settings,
                progress: progress,
                pagesRead: pagesRead,
                date: date
            )
            progress = result.progress
            // 설정이 업데이트되었으면 새 설정 사용
            if let updatedSettings = result.updatedSettings {
                settings = updatedSettings
            }
        }

        return progress
    }

    // MARK: - createInitialSchedule Tests

    /// 정상 케이스: 10일간 100페이지 읽기 (나머지 없음)
    @Test("createInitialSchedule - 정상 케이스 (나머지 없음)")
    func createInitialSchedule_noRemainder() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19")  // 10일
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        // 10일간 매일 10페이지씩
        #expect(result.dailyReadingRecords.count == 10)
        #expect(result.lastReadPage == 0)

        // 첫날 목표: 10페이지
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 10)
        // 마지막 날 목표: 100페이지
        #expect(result.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    /// 정상 케이스: 나머지 페이지 있는 경우
    @Test("createInitialSchedule - 나머지 있는 경우")
    func createInitialSchedule_withRemainder() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-16")  // 7일
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        // 100 ÷ 7 = 14 ... 2
        // 7일간 기본 14페이지, 마지막 2일에 1페이지씩 추가
        #expect(result.dailyReadingRecords.count == 7)

        // 나머지 페이지가 뒤 날짜에 제대로 분배 70 -> 85 -> 100
        #expect(result.dailyReadingRecords["2025-01-14"]?.targetPages == 70)
        #expect(result.dailyReadingRecords["2025-01-15"]?.targetPages == 85)
        // 마지막 날은 정확히 100페이지
        #expect(result.dailyReadingRecords["2025-01-16"]?.targetPages == 100)
    }

    /// 정상 케이스: 제외일이 있는 경우
    @Test("createInitialSchedule - 제외일 있음")
    func createInitialSchedule_withExcludedDays() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19"),  // 10일
            excludedReadingDays: [
                makeDate("2025-01-12"),  // 제외일 1
                makeDate("2025-01-15")   // 제외일 2
            ]
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        // 10일 중 2일 제외 = 8일
        // 100 ÷ 8 = 12 ... 4
        #expect(result.dailyReadingRecords.count == 8)

        // 제외일에는 기록 없음
        #expect(result.dailyReadingRecords["2025-01-12"] == nil)
        #expect(result.dailyReadingRecords["2025-01-15"] == nil)

        // 첫날은 기록 있음
        #expect(result.dailyReadingRecords["2025-01-10"] != nil)
    }

    /// 단일 날짜 케이스
    @Test("createInitialSchedule - 단일 날짜")
    func createInitialSchedule_singleDay() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 50,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-10")  // 같은 날
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        #expect(result.dailyReadingRecords.count == 1)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 50)
    }

    // MARK: - applyTodayReading Tests

    /// 정상 케이스: 목표 달성
    @Test("applyTodayReading - 목표 달성")
    func applyTodayReading_targetMet() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19")
        )

        // 완전한 초기 스케줄 생성 (10일간 매일 10페이지)
        let progress = try makeCompleteSchedule(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-19")
        )

        // 첫날 목표(10페이지) 정확히 달성
        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 10,
            date: makeDate("2025-01-10")
        )

        // 목표와 일치하면 재조정 없음
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(result.progress.lastReadPage == 10)
        #expect(result.updatedSettings == nil)

        // 나머지 날들의 스케줄은 그대로 유지
        #expect(result.progress.dailyReadingRecords.count == 10)
        #expect(result.progress.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    /// 정상 케이스: 목표보다 많이 읽음 → 재조정
    @Test("applyTodayReading - 목표 초과 → 재조정")
    func applyTodayReading_exceedsTarget() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")  // 5일
        )

        // 초기 스케줄: 매일 20페이지씩
        let progress = makeProgress(
            dailyReadingRecords: [
                "2025-01-10": ReadingRecord(targetPages: 20, pagesRead: 0),
                "2025-01-11": ReadingRecord(targetPages: 40, pagesRead: 0),
                "2025-01-12": ReadingRecord(targetPages: 60, pagesRead: 0),
                "2025-01-13": ReadingRecord(targetPages: 80, pagesRead: 0),
                "2025-01-14": ReadingRecord(targetPages: 100, pagesRead: 0)
            ],
            lastReadDate: nil,
            lastReadPage: 0
        )

        // 첫날 30페이지 읽음 (목표 20 초과)
        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 30,
            date: makeDate("2025-01-10")
        )

        // 첫날은 30페이지로 고정
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 30)

        // 나머지 날들이 재조정됨 (70페이지를 4일에 분배 -> 17...2)
        #expect(result.progress.lastReadPage == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 47)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    /// 정상 케이스: 목표보다 덜 읽음 → 재조정
    @Test("applyTodayReading - 목표 미달 → 재조정")
    func applyTodayReading_underTarget() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")  // 5일
        )

        let progress = makeProgress(
            dailyReadingRecords: [
                "2025-01-10": ReadingRecord(targetPages: 20, pagesRead: 0),
                "2025-01-11": ReadingRecord(targetPages: 40, pagesRead: 0),
                "2025-01-12": ReadingRecord(targetPages: 60, pagesRead: 0),
                "2025-01-13": ReadingRecord(targetPages: 80, pagesRead: 0),
                "2025-01-14": ReadingRecord(targetPages: 100, pagesRead: 0)
            ],
            lastReadDate: nil,
            lastReadPage: 0
        )

        // 첫날 10페이지만 읽음 (목표 20 미달)
        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 10,
            date: makeDate("2025-01-10")
        )

        // 첫날은 10페이지로 고정
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 10)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)

        // 나머지 날들이 재조정됨 (90페이지를 4일에 분배 -> 22...2)
        #expect(result.progress.lastReadPage == 10)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 32)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    /// 제외일에 읽기 → excludedDays에서 제거
    @Test("applyTodayReading - 제외일에 읽기")
    func applyTodayReading_onExcludedDay() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14"),
            excludedReadingDays: [
                makeDate("2025-01-11")  // 제외일
            ]
        )

        // 완전한 초기 스케줄 생성 (제외일 제외한 4일: 100÷4 = 25페이지씩)
        let progress = try makeCompleteSchedule(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-14"),
            excludedDays: [makeDate("2025-01-11")]
        )

        // 제외일(1/11)에 독서 기록
        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 30,
            date: makeDate("2025-01-11")
        )

        // 제외일 목록이 업데이트되어야 함
        #expect(result.updatedSettings != nil)
        #expect(result.updatedSettings?.excludedReadingDays.count == 0)  // 제외일이 제거됨

        // 해당 날짜에 기록됨
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.pagesRead == 30)
        #expect(result.progress.dailyReadingRecords["2025-01-11"]?.targetPages == 30)

        // 제외일이 독서일로 바뀌었으므로 전체가 5일이 됨
        // 남은 페이지: 70, 남은 일수: 3일 (12, 13, 14) → 23...1
        #expect(result.progress.dailyReadingRecords.count == 5)  // 이제 5일 모두 포함
        #expect(result.progress.dailyReadingRecords["2025-01-12"]?.targetPages == 53)
        #expect(result.progress.dailyReadingRecords["2025-01-13"]?.targetPages == 76)
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)

        // 10일에는 안 읽음 (초기 상태 유지)
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 0)
    }

    // MARK: - adjustFutureTargets Tests

    /// 정상 케이스: 미래 목표 재조정
    @Test("adjustFutureTargets - 정상 재조정")
    func adjustFutureTargets_normal() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")
        )

        let progress = makeProgress(
            dailyReadingRecords: [
                "2025-01-10": ReadingRecord(targetPages: 30, pagesRead: 30),  // 이미 읽음
                "2025-01-11": ReadingRecord(targetPages: 40, pagesRead: 0),
                "2025-01-12": ReadingRecord(targetPages: 60, pagesRead: 0),
                "2025-01-13": ReadingRecord(targetPages: 80, pagesRead: 0),
                "2025-01-14": ReadingRecord(targetPages: 100, pagesRead: 0)
            ],
            lastReadDate: makeDate("2025-01-10"),
            lastReadPage: 30
        )

        // 1/10 이후 재조정 (70페이지를 4일에 분배 -> 17...2)
        let result = try calculator.adjustFutureTargets(
            settings: settings,
            progress: progress,
            fromDate: makeDate("2025-01-10")
        )

        // 이미 읽은 날은 유지
        #expect(result.dailyReadingRecords["2025-01-10"]?.pagesRead == 30)

        // 다음날부터 새 스케줄
        #expect(result.dailyReadingRecords["2025-01-11"]?.pagesRead == 0)
        #expect(result.dailyReadingRecords["2025-01-11"]?.targetPages == 47)
        #expect(result.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }

    // MARK: - rescheduleOnAppOpen Tests

    /// 정상 케이스: 며칠간 안 읽고 재접속
    @Test("rescheduleOnAppOpen - 정상 재분배")
    func rescheduleOnAppOpen_normal() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-19")
        )

        // 완전한 초기 스케줄 생성 후 첫날만 독서 (10일간 매일 10페이지)
        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-19"),
            readDates: [
                makeDate("2025-01-10"): 10  // 첫날만 목표 달성
            ]
        )

        // 검증: 첫날 독서 완료, 나머지는 아직 안 읽음
        #expect(progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(progress.dailyReadingRecords["2025-01-11"]?.pagesRead == 0)
        #expect(progress.dailyReadingRecords.count == 10)

        // 1/13에 재접속 (2일 건너뜀)
        let result = try calculator.rescheduleOnAppOpen(
            settings: settings,
            progress: progress,
            today: makeDate("2025-01-13")
        )

        // 1/10은 그대로 유지
        #expect(result.dailyReadingRecords["2025-01-10"]?.pagesRead == 10)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 10)

        // 1/13부터 새 스케줄 (남은 90페이지를 7일에 분배)
        #expect(result.dailyReadingRecords["2025-01-13"] != nil)
        #expect(result.dailyReadingRecords["2025-01-13"]?.targetPages == 22)
        #expect(result.dailyReadingRecords["2025-01-19"]?.targetPages == 100)
    }

    /// 에러 케이스: 목표일 지남
    @Test("rescheduleOnAppOpen - targetDatePassed 에러")
    func rescheduleOnAppOpen_targetDatePassed() {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-15")
        )

        let progress = makeProgress()

        // 목표일 이후 재접속
        #expect(throws: ScheduleCalculationError.self) {
            try calculator.rescheduleOnAppOpen(
                settings: settings,
                progress: progress,
                today: makeDate("2025-01-20")  // 목표일 지남
            )
        }
    }

    /// 오늘 이미 읽은 경우 → 재분배 안 함
    @Test("rescheduleOnAppOpen - 오늘 이미 읽음")
    func rescheduleOnAppOpen_alreadyReadToday() throws {
        let settings = makeSettings(
            startPage: 1,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-15")
        )

        // 완전한 초기 스케줄 생성 후 1/12에 독서 기록
        // 초기: 6일간 100페이지 → 16...4 (마지막 4일에 17페이지씩)
        // 1/10에 16페이지 읽고 재조정됨 → 남은 84페이지를 5일에 분배
        let progress = try makeProgressWithReadingHistory(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-15"),
            readDates: [
                makeDate("2025-01-10"): 16,  // 첫날 목표 달성
                makeDate("2025-01-12"): 50   // 셋째날 독서 (오늘)
            ]
        )

        // 검증: 1/10과 1/12에 독서 완료
        #expect(progress.dailyReadingRecords["2025-01-10"]?.pagesRead == 16)
        #expect(progress.dailyReadingRecords["2025-01-12"]?.pagesRead == 50)
        #expect(progress.lastReadPage == 50)

        // 1/12에 재접속 (오늘 이미 읽음)
        let result = try calculator.rescheduleOnAppOpen(
            settings: settings,
            progress: progress,
            today: makeDate("2025-01-12")
        )

        // 변경 없음 - 오늘 이미 읽었으므로 재분배 불필요
        #expect(result.lastReadPage == 50)
        #expect(result.dailyReadingRecords["2025-01-12"]?.pagesRead == 50)
        #expect(result.dailyReadingRecords["2025-01-10"]?.pagesRead == 16)
    }

    // MARK: - rescheduleForSettingsChange Tests

    /// 시작일 미래로 변경 → 전체 재계산
    @Test("rescheduleForSettingsChange - 시작일 미래로 변경")
    func rescheduleForSettingsChange_futureStartDate() throws {
        let oldSettings = makeSettings(
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-20")
        )

        let newSettings = makeSettings(
            startDate: makeDate("2025-01-25"),  // 미래로 변경
            targetEndDate: makeDate("2025-02-05")
        )

        let progress = makeProgress(
            dailyReadingRecords: [
                "2025-01-10": ReadingRecord(targetPages: 10, pagesRead: 10)
            ]
        )

        let result = try calculator.rescheduleForSettingsChange(
            oldSettings: oldSettings,
            newSettings: newSettings,
            progress: progress,
            today: makeDate("2025-01-15")
        )

        // 전체 새로 계산됨
        #expect(result.dailyReadingRecords["2025-01-25"] != nil)
    }

    /// 종료일 변경 → 재분배
    @Test("rescheduleForSettingsChange - 종료일 변경")
    func rescheduleForSettingsChange_endDateChanged() throws {
        let oldSettings = makeSettings(
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-20")
        )

        let newSettings = makeSettings(
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-25")  // 종료일 연장
        )

        let progress = makeProgress(
            dailyReadingRecords: [
                "2025-01-10": ReadingRecord(targetPages: 30, pagesRead: 30)
            ],
            lastReadDate: makeDate("2025-01-10"),
            lastReadPage: 30
        )

        let result = try calculator.rescheduleForSettingsChange(
            oldSettings: oldSettings,
            newSettings: newSettings,
            progress: progress,
            today: makeDate("2025-01-12")
        )

        // 오늘부터 새 종료일까지 재분배
        #expect(result.dailyReadingRecords["2025-01-25"] != nil)
    }

    // MARK: - 중간 페이지 시작 Tests

    /// 중간 페이지부터 시작 (30~100)
    @Test("createInitialSchedule - 중간 페이지 시작 (30~100)")
    func createInitialSchedule_startFromMiddlePage() throws {
        let settings = makeSettings(
            startPage: 30,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-16")  // 7일
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        // 30~100 = 71페이지 (30포함 100포함)
        // 71÷7 = 10...1 → 기본 10페이지, 마지막 1일에 1페이지 추가
        #expect(result.dailyReadingRecords.count == 7)
        #expect(result.lastReadPage == 29)  // 30페이지 이전

        // 첫날 목표: 30 + 10 = 39페이지 (30부터 읽음)
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 39)
        // 마지막 날 목표: 정확히 100페이지
        #expect(result.dailyReadingRecords["2025-01-16"]?.targetPages == 100)
    }

    /// 중간 페이지 + 나머지 있는 경우
    @Test("createInitialSchedule - 중간 페이지 + 나머지")
    func createInitialSchedule_middlePageWithRemainder() throws {
        let settings = makeSettings(
            startPage: 50,
            targetEndPage: 120,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-16")  // 7일
        )

        let result = try calculator.createInitialSchedule(settings: settings)

        // 50~120 = 71페이지 (50포함 120포함)
        // 71÷7 = 10...1 → 기본 10페이지, 마지막 1일에 1페이지 추가
        #expect(result.dailyReadingRecords.count == 7)
        #expect(result.lastReadPage == 49)

        // 첫날: 50 + 10 = 59
        #expect(result.dailyReadingRecords["2025-01-10"]?.targetPages == 59)
        // 마지막 날: 정확히 120
        #expect(result.dailyReadingRecords["2025-01-16"]?.targetPages == 120)
    }

    /// 중간 페이지 + applyTodayReading
    @Test("applyTodayReading - 중간 페이지 독서 진행")
    func applyTodayReading_middlePage() throws {
        let settings = makeSettings(
            startPage: 30,
            targetEndPage: 100,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-14")  // 5일
        )

        // 초기 스케줄: 30~100 = 71페이지, 71÷5 = 14...1
        let progress = try makeCompleteSchedule(
            startDate: makeDate("2025-01-10"),
            endDate: makeDate("2025-01-14"),
            startPage: 30,
            targetEndPage: 100
        )

        // 첫날 목표 확인 (30페이지부터 14페이지를 읽으면 목표는 43)
        #expect(progress.dailyReadingRecords["2025-01-10"]?.targetPages == 43)

        // 첫날 50페이지까지 읽음 (목표 43 초과)
        let result = try calculator.applyTodayReading(
            settings: settings,
            progress: progress,
            pagesRead: 50,
            date: makeDate("2025-01-10")
        )

        // 첫날은 50으로 고정
        #expect(result.progress.dailyReadingRecords["2025-01-10"]?.targetPages == 50)
        #expect(result.progress.lastReadPage == 50)

        // 남은 50페이지를 4일에 재분배: 50÷4 = 12...2
        #expect(result.progress.dailyReadingRecords["2025-01-14"]?.targetPages == 100)
    }
}
