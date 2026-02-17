//
//  ReadingTimeZoneProviding.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/17/26.
//

import Foundation

/// 읽기 기록 생성 시점의 타임존 식별자를 제공합니다.
protocol ReadingTimeZoneProviding {
    func currentTimeZoneID() -> String
}

struct SystemReadingTimeZoneProvider: ReadingTimeZoneProviding {
    func currentTimeZoneID() -> String {
        let identifier = TimeZone.autoupdatingCurrent.identifier
        return identifier.isEmpty ? ReadingRecord.legacyDefaultTimeZoneID : identifier
    }
}
