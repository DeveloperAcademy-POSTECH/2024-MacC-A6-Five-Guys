//
//  FGUserBook+ToUserBookV2.swift
//  FiveGuyes
//
//  Created by zaehorang on 4/6/25.
//

extension FGUserBook {
    func toUserBookV2() -> UserBookSchemaV2.UserBookV2 {
        return UserBookSchemaV2.UserBookV2(
            id: self.id,
            bookMetaData: self.bookMetaData.toBookMetaData(),
            userSettings: self.userSettings.toUserSettings(),
            readingProgress: self.readingProgress.toReadingProgress(),
            completionStatus: self.completionStatus.toCompletionStatus()
        )
    }
}

extension FGBookMetaData {
    func toBookMetaData() -> BookMetaData {
        return BookMetaData(
            title: self.title,
            author: self.author,
            coverURL: self.coverImageURL,
            totalPages: self.totalPages
        )
    }
}

extension FGUserSetting {
    func toUserSettings() -> UserSettings {
        return UserSettings(
            startPage: self.startPage,
            targetEndPage: self.targetEndPage,
            startDate: self.startDate,
            targetEndDate: self.targetEndDate,
            nonReadingDays: self.excludedReadingDays
        )
    }
}

extension FGCompletionStatus {
    func toCompletionStatus() -> CompletionStatus {
        return CompletionStatus(
            isCompleted: self.isCompleted,
            completionReview: self.reviewAfterCompletion
        )
    }
}

extension FGReadingProgress {
    func toReadingProgress() -> ReadingProgress {
        return ReadingProgress(
            readingRecords: self.dailyReadingRecords,
            lastReadDate: self.lastReadDate,
            lastPagesRead: self.lastReadPage
        )
    }
}
