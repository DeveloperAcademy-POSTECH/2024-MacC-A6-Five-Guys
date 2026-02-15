//
//  ReadingDateKey.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/14/26.
//

import Foundation

/// 독서 기록에서 사용하는 날짜 키(`yyyy-MM-dd`)를 표현하는 값 타입입니다.
/// 키 생성/파싱은 앱 캘린더(`Calendar.app`) 타임존 규칙(현재 한국 기준)과
/// 고정 locale(`en_US_POSIX`)을 함께 사용해 기기 언어/지역 설정 영향 없이 동일하게 동작합니다.
struct ReadingDateKey: Hashable, Comparable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(date: Date, calendar: Calendar = .app) {
        let formatter = Self.makeFormatter(timeZone: calendar.timeZone)
        rawValue = formatter.string(from: date)
    }

    init?(parsing rawValue: String, calendar: Calendar = .app) {
        let formatter = Self.makeFormatter(timeZone: calendar.timeZone)
        guard let date = formatter.date(from: rawValue),
              formatter.string(from: date) == rawValue else {
            return nil
        }

        self.rawValue = rawValue
    }

    func toDate(calendar: Calendar = .app) -> Date? {
        let formatter = Self.makeFormatter(timeZone: calendar.timeZone)
        return formatter.date(from: rawValue)
    }

    /// 저장소에서 읽은 raw 키를 도메인 비교용 키로 변환합니다.
    ///
    /// - 파싱 가능한 정규 키(`yyyy-MM-dd`)는 타입으로 정규화합니다.
    /// - 파싱이 불가능한 과거/오염 데이터는 raw 값을 보존해 비교 경로에서 드롭되지 않게 유지합니다.
    ///
    /// 이 메서드를 통해 도메인 전역의 fallback 규칙을 한곳에서 통일합니다.
    static func fromStoredKey(_ rawKey: String, calendar: Calendar = .app) -> ReadingDateKey {
        ReadingDateKey(parsing: rawKey, calendar: calendar) ?? ReadingDateKey(rawValue: rawKey)
    }

    static func < (lhs: ReadingDateKey, rhs: ReadingDateKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    private static func makeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        // 저장 키 포맷을 사용자 locale 변화와 분리하기 위한 고정 규칙입니다.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // 도메인 날짜 기준(현재 Asia/Seoul)을 formatter에도 동일하게 적용합니다.
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
