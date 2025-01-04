//
//  CalendarCellModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/4/25.
//

import Foundation

/// 캘린더 셀의 상태와 로직을 관리하는 모델.
/// 시작 날짜, 종료 날짜, 제외된 날짜를 추적하고,
/// 특정 날짜의 상태를 판별하는 메서드를 제공합니다.
@Observable
final class CalendarCellModel: ObservableObject {
    // MARK: - Properties
    
    /// 오늘 날짜 (시간 제외)
    let adjustedToday: Date
    
    /// 날짜 계산에 사용할 캘린더 인스턴스
    private let calendar = Calendar.current
    
    /// 선택된 범위의 시작 날짜
    private var startDate: Date?
    
    /// 선택된 범위의 종료 날짜
    private var endDate: Date?
    
    /// 선택된 범위에서 제외된 날짜 리스트
    private var excludedDates: [Date]
    
    /// 선택된 날짜가 확정되었는지 여부
    private(set) var isConfirmed: Bool = false
    
    // MARK: - 초기화
    
    /// 모델 초기화
    /// - Parameters:
    ///   - adjustedToday: 기준이 되는 오늘 날짜 (-4시간 조정된 날짜)
    ///   - startDate: 선택된 범위의 시작 날짜 (선택 사항)
    ///   - endDate: 선택된 범위의 종료 날짜 (선택 사항)
    ///   - excludedDates: 제외된 날짜 리스트 (선택 사항)
    ///   - isConfirmed: 선택된 날짜가 확정되었는지 여부
    init(adjustedToday: Date, startDate: Date? = nil, endDate: Date? = nil, excludedDates: [Date] = [], isConfirmed: Bool = false) {
        let calendar = Calendar.current
        
        self.adjustedToday = calendar.startOfDay(for: adjustedToday)
        self.startDate = startDate.map { calendar.startOfDay(for: $0) }
        self.endDate = endDate.map { calendar.startOfDay(for: $0) }
        self.excludedDates = excludedDates.map { calendar.startOfDay(for: $0) }
        self.isConfirmed = isConfirmed
    }
    
    // MARK: - Public Methods
    
    /// 시작 날짜와 종료 날짜가 설정되었는지 확인합니다.
    /// - Returns: 두 날짜가 설정되었으면 `true`, 그렇지 않으면 `false`.
    func isRangeComplete() -> Bool {
        return startDate != nil && endDate != nil
    }
    
    /// 특정 날짜가 선택된 범위 내의 중간 날짜인지 확인합니다.
    /// 제외된 날짜는 중간 날짜로 간주되지 않습니다.
    /// - Parameter date: 확인할 날짜
    /// - Returns: 범위 내의 날짜이면서 제외되지 않은 경우 `true`, 아니면 `false`.
    func isBetweenSelectedDays(for date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        guard let startDate, let endDate else { return false }
        return day > startDate && day < endDate && !excludedDates.contains(day)
    }
    
    /// 특정 날짜가 오늘 이전인지 확인합니다.
    /// - Parameter date: 확인할 날짜
    /// - Returns: 오늘 이전 날짜이면 `true`, 그렇지 않으면 `false`.
    func isPastDate(for date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day < adjustedToday
    }
    
    /// 특정 날짜가 시작 날짜 또는 종료 날짜인지 확인합니다.
    /// - Parameter date: 확인할 날짜
    /// - Returns: 시작 날짜나 종료 날짜에 해당하면 `true`, 아니면 `false`.
    func isStartOrEndDate(for date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day == startDate || day == endDate
    }
    
    /// 특정 날짜가 시작 날짜인지 확인합니다.
    /// - Parameter date: 확인할 날짜
    /// - Returns: 시작 날짜에 해당하면 `true`, 아니면 `false`.
    func isStartDate(for date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day == startDate
    }
    
    /// 선택된 날짜에 따라 상태를 업데이트합니다.
    /// - Parameter date: 선택된 날짜
    func updateCellSelection(for date: Date) {
        let day = calendar.startOfDay(for: date)
        
        guard day >= adjustedToday else { return } // 과거 날짜는 선택 불가
        
        if isConfirmed {
            // 날짜가 확정된 경우 제외 날짜를 추가하거나 제거
            toggleExcludeDate(day)
        } else {
            // 확정되지 않은 경우 시작 날짜와 종료 날짜를 업데이트
            if let start = startDate, day < start {
                // 선택한 날짜가 시작 날짜 이전인 경우: 시작 날짜를 업데이트
                startDate = day
            } else if let end = endDate, day > end {
                // 선택한 날짜가 종료 날짜 이후인 경우: 종료 날짜를 업데이트
                endDate = day
            } else if let start = startDate, let end = endDate, day > start && day < end {
                // 시작과 종료 날짜 사이의 날짜를 선택한 경우: 종료 날짜로 업데이트
                endDate = day
            } else if day == startDate {
                startDate = nil
            } else if day == endDate {
                endDate = nil
            } else {
                // 시작 또는 종료 날짜가 설정되지 않은 경우
                if startDate == nil {
                    startDate = day
                } else if endDate == nil {
                    endDate = day
                }
            }
            
            // 제외된 날짜 업데이트 로직 추가
            updateExcludedDates()
        }
    }
    
    /// 시작 날짜와 종료 날짜를 기준으로 제외된 날짜 리스트를 업데이트합니다.
    /// 범위에 포함되지 않는 제외된 날짜를 제거합니다.
    private func updateExcludedDates() {
        guard let startDate, let endDate else { return }
        excludedDates.removeAll { date in
            date < startDate || date > endDate
        }
    }
    
    /// 특정 날짜를 제외 리스트에서 추가하거나 제거합니다.
    /// - Parameter date: 제외할 날짜
    func toggleExcludeDate(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        
        guard isConfirmed else { return } // 확정되지 않은 경우 제외 불가
        guard !isStartOrEndDate(for: day) else { return } // 시작 날짜와 종료 날짜는 제외 불가
        
        if excludedDates.contains(day) {
            excludedDates.removeAll { $0 == day }
        } else {
            excludedDates.append(day)
        }
    }
    
    /// 현재 선택된 날짜 범위를 확정합니다.
    func confirmDates() {
        guard isRangeComplete() else { return }
        isConfirmed = true
    }
    
    // MARK: - Getter Methods
    
    /// 시작 날짜를 가져옵니다.
    /// - Returns: 시작 날짜 또는 `nil`
    func getStartDate() -> Date? {
        return startDate
    }
    
    /// 종료 날짜를 가져옵니다.
    /// - Returns: 종료 날짜 또는 `nil`
    func getEndDate() -> Date? {
        return endDate
    }
    
    /// 제외된 날짜 리스트를 가져옵니다.
    /// - Returns: 제외된 날짜 리스트
    func getExcludedDates() -> [Date] {
        return excludedDates
    }
    
    /// 현재 날짜 범위가 확정되었는지 여부를 반환합니다.
    /// - Returns: 날짜 범위가 확정되었으면 `true`, 그렇지 않으면 `false`.
    func getConfirmed() -> Bool {
        return isConfirmed
    }
}
