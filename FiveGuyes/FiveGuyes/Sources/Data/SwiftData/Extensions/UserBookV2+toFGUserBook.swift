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
        let resolvedStartDateKey = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: startDateKey,
            legacyDate: startDate
        )
        let resolvedTargetEndDateKey = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: targetEndDateKey,
            legacyDate: targetEndDate
        )
        let resolvedExcludedReadingDayKeys = SettingsDateKeyPolicy.resolveDateKeys(
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
