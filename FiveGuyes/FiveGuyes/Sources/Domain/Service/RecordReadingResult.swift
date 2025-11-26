//
//  RecordReadingResult.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-01-08.
//

import Foundation

/// recordReading() 메서드의 결과를 나타내는 enum
enum RecordReadingResult {
    /// 정상적으로 기록됨 (완독 아님)
    case recorded(updatedBook: FGUserBook)

    /// 완독 완료
    case completed(updatedBook: FGUserBook)

    /// 날짜 자동 연장됨 (마지막 날에 목표 미달)
    case dateExtended

    /// 목표 페이지 초과 (사용자 확인 필요)
    case exceedsTarget(currentTarget: Int)
}
