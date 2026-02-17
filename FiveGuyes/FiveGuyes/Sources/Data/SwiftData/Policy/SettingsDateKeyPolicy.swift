//
//  SettingsDateKeyPolicy.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/17/26.
//

import Foundation

enum SettingsDateKeyPolicy {
    /// legacy `Date` 기반 설정 데이터를 key로 보정할 때는 legacy fallback 정책 타임존을 유지합니다.
    private static var legacySettingsCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: LegacyTimeZoneFallbackPolicy.settingsDateKeyFallbackTimeZoneID)
            ?? TimeZone(secondsFromGMT: 0)
            ?? .autoupdatingCurrent
        return calendar
    }()

    static func resolveDateKey(rawKey: String?, legacyDate: Date) -> ReadingDateKey {
        if let rawKey,
           let parsedKey = ReadingDateKey(parsing: rawKey, calendar: .app) {
            return parsedKey
        }

        return ReadingDateKey(date: legacyDate, calendar: legacySettingsCalendar)
    }

    static func resolveDateKeys(rawKeys: [String]?, legacyDates: [Date]) -> [ReadingDateKey] {
        guard let rawKeys, !rawKeys.isEmpty else {
            return legacyDates.map { ReadingDateKey(date: $0, calendar: legacySettingsCalendar) }
        }

        var resolvedKeys: [ReadingDateKey] = []
        resolvedKeys.reserveCapacity(max(rawKeys.count, legacyDates.count))

        for (index, rawKey) in rawKeys.enumerated() {
            if let parsedKey = ReadingDateKey(parsing: rawKey, calendar: .app) {
                resolvedKeys.append(parsedKey)
                continue
            }

            if legacyDates.indices.contains(index) {
                resolvedKeys.append(ReadingDateKey(date: legacyDates[index], calendar: legacySettingsCalendar))
            }
        }

        if rawKeys.count < legacyDates.count {
            for index in rawKeys.count..<legacyDates.count {
                resolvedKeys.append(ReadingDateKey(date: legacyDates[index], calendar: legacySettingsCalendar))
            }
        }

        if resolvedKeys.isEmpty {
            return legacyDates.map { ReadingDateKey(date: $0, calendar: legacySettingsCalendar) }
        }

        return resolvedKeys
    }
}
