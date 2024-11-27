//
//  ReadingProgressProtocol.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

import Foundation

protocol ReadingProgressProtocol: AnyObject {
    associatedtype Settings
    
    var readingRecords: [String: ReadingRecord] { get set }
    var lastReadDate: Date? { get set }
    var lastPagesRead: Int { get set }
    
    /// Date 타입의 값을 readingRecords의 키 값으로 사용할 수 있게 변환해주는 메서드
    func getReadingRecordsKey(_ date: Date) -> String
    /// Date 타입의 값을 readingRecords의 키 값으로 사용할 수 있게 변환해주는 메서드 ⏰
    func getAdjustedReadingRecordsKey(_ date: Date) -> String
    
    /// 특정 날의 목표량과 실제 읽은 페이지의 수를 가져오는 메서드 ⏰
    func getAdjustedReadingRecord(for date: Date) -> ReadingRecord?
    /// 현재 날짜를 기준으로 해당 주의 날짜와 타겟 페이지를 가져오는 메서드 ⏰
    func getAdjustedWeeklyRecorded(from today: Date) -> [ReadingRecord?]
    
    /// `pagesRead`가 0이 아닌 날의 수를 반환하는 메서드
    /// 지금까지 독서를 한 날의 수
    func nonZeroReadingDaysCount() -> Int
    /// 오늘 이후 다음 읽기 예정일을 반환하는 메서드
    func findNextReadingDay() -> Date?
    
    /// 하루에 몇 페이지를 읽어야 하는지를 반환하는 메서드
    func findNextReadingPagesPerDay(for settings: Settings) -> Int
}
