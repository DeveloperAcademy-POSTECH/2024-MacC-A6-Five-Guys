//
//  UserBookV2+ToFGUserBook.swift
//  FiveGuyes
//
//  Created by zaehorang on 4/6/25.
//

import Foundation

extension UserBookSchemaV2.UserBookV2 {
    func toFGUserBook() -> FGUserBook {
        return FGUserBook(
            id: self.id,
            bookMetaData: self.bookMetaData.toFGBookMetaData(),
            userSettings: self.userSettings.toFGUserSetting(),
            readingProgress: self.readingProgress.toFGReadingProgress(),
            completionStatus: self.completionStatus.toFGCompletionStatus()
        )
    }
}

extension BookMetaData {
    func toFGBookMetaData() -> FGBookMetaData {
        return FGBookMetaData(
            title: self.title,
            author: self.author,
            coverImageURL: self.coverURL,
            totalPages: self.totalPages
        )
    }
}

extension UserSettings {
    func toFGUserSetting() -> FGUserSetting {
        let resolvedStartDateKey = Self.resolveDateKey(
            rawKey: startDateKey,
            legacyDate: startDate
        )
        let resolvedTargetEndDateKey = Self.resolveDateKey(
            rawKey: targetEndDateKey,
            legacyDate: targetEndDate
        )
        let resolvedExcludedReadingDayKeys = Self.resolveDateKeys(
            rawKeys: nonReadingDayKeys,
            legacyDates: nonReadingDays
        )

        return FGUserSetting(
            startPage: self.startPage,
            targetEndPage: self.targetEndPage,
            startDateKey: resolvedStartDateKey,
            targetEndDateKey: resolvedTargetEndDateKey,
            excludedReadingDayKeys: resolvedExcludedReadingDayKeys
        )
    }

    // legacy `Date` 기반 설정 데이터를 최초 key로 채울 때는 기존 운영 기준(Asia/Seoul)을 사용합니다.
    private static var legacySettingsCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
        return calendar
    }()

    private static func resolveDateKey(rawKey: String?, legacyDate: Date) -> ReadingDateKey {
        if let rawKey,
           let parsedKey = ReadingDateKey(parsing: rawKey, calendar: .app) {
            return parsedKey
        }

        return ReadingDateKey(date: legacyDate, calendar: legacySettingsCalendar)
    }

    private static func resolveDateKeys(rawKeys: [String]?, legacyDates: [Date]) -> [ReadingDateKey] {
        guard let rawKeys, !rawKeys.isEmpty else {
            return legacyDates.map { ReadingDateKey(date: $0, calendar: legacySettingsCalendar) }
        }

        var resolvedKeys: [ReadingDateKey] = []
        resolvedKeys.reserveCapacity(rawKeys.count)

        for (index, rawKey) in rawKeys.enumerated() {
            if let parsedKey = ReadingDateKey(parsing: rawKey, calendar: .app) {
                resolvedKeys.append(parsedKey)
                continue
            }

            if legacyDates.indices.contains(index) {
                resolvedKeys.append(ReadingDateKey(date: legacyDates[index], calendar: legacySettingsCalendar))
            }
        }

        if resolvedKeys.isEmpty {
            return legacyDates.map { ReadingDateKey(date: $0, calendar: legacySettingsCalendar) }
        }

        return resolvedKeys
    }
}

extension CompletionStatus {
    func toFGCompletionStatus() -> FGCompletionStatus {
        FGCompletionStatus(
            isCompleted: self.isCompleted,
            reviewAfterCompletion: self.completionReview
        )
    }
}

extension ReadingProgress {
    func toFGReadingProgress() -> FGReadingProgress {
        FGReadingProgress(
            dailyReadingRecords: self.readingRecords,
            lastReadDate: self.lastReadDate,
            lastReadPage: self.lastPagesRead
        )
    }
}
