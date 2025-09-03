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
    let startDate: Date
    let targetEndDate: Date
    let excludedReadingDays: [Date]
    
    /// 독서 시작일부터 종료일까지 포함된 각 주의 시작 날짜 배열을 반환
    func weeklyStartDates(today: Date) -> [Date] {
        // 오늘이 시작일보다 빠르면 오늘부터 계산 시작
        let effectiveStartDay = today < startDate ? today : startDate
        
        let calendar = Calendar.app
        let firstWeekStart = calendar.dateInterval(of: .weekOfMonth, for: effectiveStartDay)?.start ?? effectiveStartDay
        let lastWeekStart = calendar.dateInterval(of: .weekOfMonth, for: targetEndDate)?.start ?? targetEndDate
        
        var startDates: [Date] = []
        var currentStart = firstWeekStart
        
        // 시작일부터 종료일까지 매주 시작 날짜 추가
        while currentStart <= lastWeekStart {
            startDates.append(currentStart)
            currentStart = calendar.date(byAdding: .weekOfMonth, value: 1, to: currentStart) ?? currentStart
        }
        
        return startDates
    }
    
    func remainingReadingDays(today: Date) -> Int {
        let remainingReadingDays = try? ReadingDateCalculator().calculateValidReadingDays(
            startDate: Date().adjustedDate(),
            endDate: targetEndDate,
            excludedDates: excludedReadingDays)
        
        return remainingReadingDays ?? 0
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
        
        // 전달된 날짜가 주의 어느 요일이더라도, 해당 주의 "시작일"로 정규화합니다.
        // 실패 시(이례적)에는 today 자체를 사용합니다.
        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: today)?.start ?? today
        
        // 일요일(0) ~ 토요일(6)까지 7칸을 순회하며, 각 날짜의 기록을 조회합니다.
        return (0..<7).map { dayOffset in
             let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            // 내부 저장은 "yyyy-MM-dd" 문자열 키를 사용합니다.
            return dailyReadingRecords[date.toYearMonthDayString()]
        }
    }
    
    func getDailyReadingRecord(for date: Date) -> ReadingRecord? { dailyReadingRecords[date.toYearMonthDayString()] }
}

struct FGCompletionStatus: Hashable {
    let isCompleted: Bool
    let reviewAfterCompletion: String
}
