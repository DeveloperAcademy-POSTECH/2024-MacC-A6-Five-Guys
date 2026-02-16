//
//  UserBookSchemaV2.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

enum UserBookSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [UserBookV2.self]
    }
}

extension UserBookSchemaV2 {
    @Model
    final class UserBookV2: Identifiable {
        @Attribute(.unique) var id: UUID

        @Relationship(deleteRule: .cascade)
        var bookMetaData: BookMetaData
        @Relationship(deleteRule: .cascade)
        var userSettings: UserSettings
        @Relationship(deleteRule: .cascade)
        var readingProgress: ReadingProgress
        @Relationship(deleteRule: .cascade)
        var completionStatus: CompletionStatus

        // MARK: init
        init(
            id: UUID = UUID(),
            bookMetaData: BookMetaData,
            userSettings: UserSettings,
            readingProgress: ReadingProgress,
            completionStatus: CompletionStatus
        ) {
            self.id = id
            self.bookMetaData = bookMetaData
            self.userSettings = userSettings
            self.readingProgress = readingProgress
            self.completionStatus = completionStatus
        }
    }
}
