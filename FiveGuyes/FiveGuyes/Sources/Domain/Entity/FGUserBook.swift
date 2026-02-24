//
//  FGUserBook.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation

struct FGUserBook: Identifiable, Hashable {
    let id: UUID
    let bookMetaData: FGBookMetaData
    var userSettings: FGUserSetting
    var readingProgress: FGReadingProgress
    var completionStatus: FGCompletionStatus
}

struct FGBookMetaData: Hashable {
    let title: String
    let author: String
    let coverImageURL: String?
    let totalPages: Int
}

struct FGUserSetting: Hashable {
    let startPage: Int
    let targetEndPage: Int
    let startDateKey: ReadingDateKey
    let targetEndDateKey: ReadingDateKey
    let excludedReadingDayKeys: [ReadingDateKey]

    /// 기존 Date 기반 호출부 호환을 위해 계산 프로퍼티를 유지합니다.
    /// 실제 저장/비교의 단일 소스는 `...DateKey`입니다.
    var startDate: Date {
        Self.resolveDate(from: startDateKey)
    }

    var targetEndDate: Date {
        Self.resolveDate(from: targetEndDateKey)
    }

    var excludedReadingDays: [Date] {
        excludedReadingDayKeys.map { Self.resolveDate(from: $0) }
    }

    init(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) {
        self.startPage = startPage
        self.targetEndPage = targetEndPage
        self.startDateKey = ReadingDateKey(date: startDate, calendar: .app)
        self.targetEndDateKey = ReadingDateKey(date: targetEndDate, calendar: .app)
        self.excludedReadingDayKeys = excludedReadingDays.map { ReadingDateKey(date: $0, calendar: .app) }
    }

    init(
        startPage: Int,
        targetEndPage: Int,
        startDateKey: ReadingDateKey,
        targetEndDateKey: ReadingDateKey,
        excludedReadingDayKeys: [ReadingDateKey]
    ) {
        self.startPage = startPage
        self.targetEndPage = targetEndPage
        self.startDateKey = startDateKey
        self.targetEndDateKey = targetEndDateKey
        self.excludedReadingDayKeys = excludedReadingDayKeys
    }

    /// 독서 시작일부터 종료일까지 포함된 각 주의 시작 날짜 배열을 반환
    func weeklyStartDates(today: Date) -> [Date] {
        let todayKey = today.readingDateKey
        let effectiveStartDay = todayKey < startDateKey ? today : startDate

        let calendar = Calendar.app
        let firstWeekStart = calendar.dateInterval(of: .weekOfMonth, for: effectiveStartDay)?.start ?? effectiveStartDay
        let lastWeekStart = calendar.dateInterval(of: .weekOfMonth, for: targetEndDate)?.start ?? targetEndDate

        var startDates: [Date] = []
        var currentStart = firstWeekStart

        while currentStart <= lastWeekStart {
            startDates.append(currentStart)
            currentStart = calendar.date(byAdding: .weekOfMonth, value: 1, to: currentStart) ?? currentStart
        }

        return startDates
    }

    func remainingReadingDays(today: Date) -> Int {
        let remainingReadingDays = try? DateMathCalculator().validDays(
            from: today,
            to: targetEndDate,
            excluding: excludedReadingDays
        )

        return remainingReadingDays ?? 0
    }

    private static func resolveDate(from key: ReadingDateKey) -> Date {
        if let resolvedDate = key.toDate(calendar: .app) {
            return resolvedDate
        }

        assertionFailure("Invalid ReadingDateKey: \(key.rawValue)")
        return Date(timeIntervalSince1970: 0)
    }
}

struct FGReadingProgress: Hashable {
    let dailyReadingRecords: [String: ReadingRecord] // 날짜와 읽은 페이지 수의 매핑
    let lastReadDate: Date?
    let lastReadPage: Int

    enum TodayReadingState: Equatable {
        /// 해당 날짜의 목표 분량을 모두 읽은 상태
        case completed
        /// 00:00~03:59 유예 기간 동안 아직 목표 분량을 읽지 못한 상태
        case gracePeriodUnfinished
        /// 유예 기간 전까지 목표를 채우지 못한 상태 (남은 목표 페이지 수 포함)
        case unfinished(targetPages: Int)
        /// 오늘은 독서가 없는 쉬는 날
        case rest
    }

    /// 주어진 날짜의 독서 상태를 진행 상황과 시간대에 따라 반환합니다.
    /// - Parameters:
    ///   - date: 평가할 날짜.
    ///   - boundaryStartHour: 하루 경계 시작 시각 (기본값은 새벽 4시).
    func readingState(on date: Date, boundaryStartHour: Int = 4) -> TodayReadingState {
        if let record = getDailyReadingRecord(for: date) {
            let isMidnightWindow = date.isInHourRange(start: 0, end: boundaryStartHour)
            if record.pagesRead == record.targetPages {
                return .completed
            } else if isMidnightWindow {
                return .gracePeriodUnfinished
            } else {
                return .unfinished(targetPages: record.targetPages)
            }
        } else {
            return .rest
        }
    }

    func weeklyRecords(from today: Date) -> [ReadingRecord?] {
        let calendar = Calendar.app

        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: today)?.start ?? today

        return (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                return nil
            }
            return dailyReadingRecords[date.readingDateKey.rawValue]
        }
    }

    func getDailyReadingRecord(for date: Date) -> ReadingRecord? { dailyReadingRecords[date.readingDateKey.rawValue] }
}

struct FGCompletionStatus: Hashable {
    let isCompleted: Bool
    let reviewAfterCompletion: String
}
