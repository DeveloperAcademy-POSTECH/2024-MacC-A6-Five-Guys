//
//  SwiftDataBookRepo+Migration.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/17/26.
//

import Foundation
import SwiftData

extension SwiftDataBookRepo {
    /// 읽기 기록 키의 legacy 포맷을 현재 도메인 정책(`Calendar.app`) 기준으로 1회 보정합니다.
    ///
    /// 왜 fetch 경계에서 1회 실행하는가:
    /// - 과거 저장 데이터와 현재 조회 키 정책이 다를 수 있어 "기록이 비어 보이는" 문제를 사전에 제거해야 합니다.
    /// - 매 조회마다 fallback 분기를 계속 두는 방식보다, 초기 1회 write-back이 이후 런타임 비용/복잡도를 줄입니다.
    static func runMigrationPipelineIfNeeded(using dependencies: MigrationDependencies) throws {
        let swiftDataBooks = try fetchBooksForMigration(using: dependencies)
        let shouldForceRecordRemediation = shouldRunReadingRecordKeyRemediation(in: swiftDataBooks)
        let shouldForceSettingsRemediation = shouldRunSettingsDateKeyRemediation(in: swiftDataBooks)

        try migrateReadingRecordKeysIfNeeded(
            books: swiftDataBooks,
            forceRemediation: shouldForceRecordRemediation,
            dependencies: dependencies
        )
        try migrateSettingsDateKeysIfNeeded(
            books: swiftDataBooks,
            forceRemediation: shouldForceSettingsRemediation,
            dependencies: dependencies
        )
    }

    private static func migrateReadingRecordKeysIfNeeded(
        books swiftDataBooks: [SDUserBook],
        forceRemediation: Bool,
        dependencies: MigrationDependencies
    ) throws {
        let wasCompleted = isReadingRecordMigrationCompleted(using: dependencies)
        guard forceRemediation || !wasCompleted else { return }

        var hasMutatedAnyBook = false

        for swiftDataBook in swiftDataBooks {
            let migration = ReadingRecordKeyMigrationV1(
                records: swiftDataBook.readingProgress.readingRecords,
                lastReadDate: swiftDataBook.readingProgress.lastReadDate
            )

            if migration.didMutate {
                swiftDataBook.readingProgress.readingRecords = migration.migratedRecords
                hasMutatedAnyBook = true
            }
        }

        if hasMutatedAnyBook {
            do {
                try dependencies.modelContext.save()
            } catch {
                dependencies.migrationLogger.logFailure(
                    stage: .recordKeyMigration,
                    migrationKeyScope: dependencies.migrationCompletionKey,
                    error: error,
                    didMutate: true
                )
                throw RepoError.fetchFailed
            }
        }

        if !wasCompleted {
            markReadingRecordMigrationCompleted(using: dependencies)
        }
    }

    private static func isReadingRecordMigrationCompleted(using dependencies: MigrationDependencies) -> Bool {
        if dependencies.migrationUserDefaults.bool(forKey: dependencies.migrationCompletionKey) {
            return true
        }

        guard dependencies.migrationCompletionKey != Self.migrationCompletionVersionKey else {
            return false
        }

        if dependencies.migrationUserDefaults.bool(forKey: Self.migrationCompletionVersionKey) {
            dependencies.migrationUserDefaults.set(true, forKey: dependencies.migrationCompletionKey)
            return true
        }

        return false
    }

    private static func markReadingRecordMigrationCompleted(using dependencies: MigrationDependencies) {
        dependencies.migrationUserDefaults.set(true, forKey: dependencies.migrationCompletionKey)
    }

    /// `UserSettings`의 DateKey 병행 필드를 1회 백필합니다.
    ///
    /// 기존 Date 데이터는 유지하고, key 필드만 채워 source-of-truth를 점진 전환합니다.
    private static func migrateSettingsDateKeysIfNeeded(
        books swiftDataBooks: [SDUserBook],
        forceRemediation: Bool,
        dependencies: MigrationDependencies
    ) throws {
        let wasCompleted = dependencies.migrationUserDefaults.bool(forKey: dependencies.settingsDateKeyMigrationCompletionKey)
        guard forceRemediation || !wasCompleted else { return }

        var hasMutatedAnyBook = false

        for swiftDataBook in swiftDataBooks {
            let settings = swiftDataBook.userSettings
            let migration = UserSettingsDateKeyMigrationV1(settings: settings)

            if migration.didMutate {
                settings.startDateKey = migration.startDateKey
                settings.targetEndDateKey = migration.targetEndDateKey
                settings.nonReadingDayKeys = migration.nonReadingDayKeys
                hasMutatedAnyBook = true
            }
        }

        if hasMutatedAnyBook {
            do {
                try dependencies.modelContext.save()
            } catch {
                dependencies.migrationLogger.logFailure(
                    stage: .settingsBackfill,
                    migrationKeyScope: dependencies.settingsDateKeyMigrationCompletionKey,
                    error: error,
                    didMutate: true
                )
                throw RepoError.fetchFailed
            }
        }

        if !wasCompleted {
            dependencies.migrationUserDefaults.set(true, forKey: dependencies.settingsDateKeyMigrationCompletionKey)
        }
    }

    private static func fetchBooksForMigration(using dependencies: MigrationDependencies) throws -> [SDUserBook] {
        do {
            return try dependencies.modelContext.fetch(FetchDescriptor<SDUserBook>())
        } catch {
            dependencies.migrationLogger.logFailure(
                stage: .fetch,
                migrationKeyScope: "\(dependencies.migrationCompletionKey),\(dependencies.settingsDateKeyMigrationCompletionKey)",
                error: error,
                didMutate: nil
            )
            throw RepoError.fetchFailed
        }
    }

    /// completion flag가 true여도 legacy/오염 신호가 재유입되면 보정 모드로 재실행한다.
    private static func shouldRunReadingRecordKeyRemediation(in books: [SDUserBook]) -> Bool {
        for swiftDataBook in books {
            let records = swiftDataBook.readingProgress.readingRecords

            if records.keys.contains(where: { hasInvalidStoredReadingDateKey($0) }) {
                return true
            }

            if records.values.contains(where: { hasNonNormalizedTimeZone($0) }) {
                return true
            }

            let migration = ReadingRecordKeyMigrationV1(
                records: records,
                lastReadDate: swiftDataBook.readingProgress.lastReadDate
            )

            if migration.didMutate {
                return true
            }
        }

        return false
    }

    private static func shouldRunSettingsDateKeyRemediation(in books: [SDUserBook]) -> Bool {
        books.contains { swiftDataBook in
            UserSettingsDateKeyMigrationV1(settings: swiftDataBook.userSettings).didMutate
        }
    }

    private static func hasInvalidStoredReadingDateKey(_ rawKey: String) -> Bool {
        ReadingDateKey(parsing: rawKey, calendar: .app) == nil
    }

    private static func hasNonNormalizedTimeZone(_ record: ReadingRecord) -> Bool {
        let trimmed = record.timeZoneID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed != record.timeZoneID
    }
}

private struct UserSettingsDateKeyMigrationV1 {
    let startDateKey: String
    let targetEndDateKey: String
    let nonReadingDayKeys: [String]
    let didMutate: Bool

    init(settings: UserSettings) {
        let migratedStartDateKey = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: settings.startDateKey,
            legacyDate: settings.startDate
        ).rawValue
        let migratedTargetEndDateKey = SettingsDateKeyPolicy.resolveDateKey(
            rawKey: settings.targetEndDateKey,
            legacyDate: settings.targetEndDate
        ).rawValue
        let migratedNonReadingDayKeys = SettingsDateKeyPolicy.resolveDateKeys(
            rawKeys: settings.nonReadingDayKeys,
            legacyDates: settings.nonReadingDays
        ).map(\.rawValue)

        self.startDateKey = migratedStartDateKey
        self.targetEndDateKey = migratedTargetEndDateKey
        self.nonReadingDayKeys = migratedNonReadingDayKeys
        self.didMutate =
            settings.startDateKey != migratedStartDateKey ||
            settings.targetEndDateKey != migratedTargetEndDateKey ||
            settings.nonReadingDayKeys != migratedNonReadingDayKeys
    }
}

private struct ReadingRecordKeyMigrationV1 {
    let migratedRecords: [String: ReadingRecord]
    let didMutate: Bool

    init(records: [String: ReadingRecord], lastReadDate: Date?) {
        guard !records.isEmpty else {
            self.migratedRecords = records
            self.didMutate = false
            return
        }

        let dayShift = Self.inferDayShift(from: records, lastReadDate: lastReadDate)
        var migratedRecords: [String: ReadingRecord] = [:]
        migratedRecords.reserveCapacity(records.count)

        for (rawKey, record) in records {
            let shiftedKey = Self.shiftedRawKey(from: rawKey, by: dayShift)
            let normalizedRecord = Self.normalize(record: record)

            if let existing = migratedRecords[shiftedKey] {
                migratedRecords[shiftedKey] = Self.mergeRecord(existing, normalizedRecord)
            } else {
                migratedRecords[shiftedKey] = normalizedRecord
            }
        }

        self.migratedRecords = migratedRecords
        self.didMutate = migratedRecords != records
    }

    /// 기본값은 0(이동 없음)입니다. 근거가 충분할 때만 -1 또는 +1 이동을 허용합니다.
    private static func inferDayShift(from records: [String: ReadingRecord], lastReadDate: Date?) -> Int {
        guard let lastReadDate else { return 0 }
        guard let anchorKey = migrationAnchorKey(from: records),
              let anchorDate = anchorKey.toDate(),
              let expectedDate = lastReadDate.readingDateKey.toDate() else {
            return 0
        }

        let diff = Calendar.app.dateComponents([.day], from: anchorDate, to: expectedDate).day ?? 0
        return abs(diff) <= 1 ? diff : 0
    }

    private static func migrationAnchorKey(from records: [String: ReadingRecord]) -> ReadingDateKey? {
        let readKeys = records
            .filter { $0.value.pagesRead > 0 }
            .keys
            .map { ReadingDateKey.fromStoredKey($0) }

        if let latestReadKey = readKeys.max() {
            return latestReadKey
        }

        return records.keys.map { ReadingDateKey.fromStoredKey($0) }.max()
    }

    private static func shiftedRawKey(from rawKey: String, by days: Int) -> String {
        let key = ReadingDateKey.fromStoredKey(rawKey)
        guard days != 0,
              let date = key.toDate(),
              let shiftedDate = Calendar.app.date(byAdding: .day, value: days, to: date) else {
            return key.rawValue
        }

        return ReadingDateKey(date: shiftedDate).rawValue
    }

    private static func mergeRecord(_ lhs: ReadingRecord, _ rhs: ReadingRecord) -> ReadingRecord {
        let merged = ReadingRecord(
            targetPages: max(lhs.targetPages, rhs.targetPages),
            pagesRead: max(lhs.pagesRead, rhs.pagesRead),
            timeZoneID: ReadingRecord.mergedTimeZoneID(
                lhs: lhs.timeZoneID,
                rhs: rhs.timeZoneID
            )
        )
        return normalize(record: merged)
    }

    private static func normalize(record: ReadingRecord) -> ReadingRecord {
        let pagesRead = max(0, record.pagesRead)
        let targetPages = max(record.targetPages, pagesRead)
        return ReadingRecord(
            targetPages: targetPages,
            pagesRead: pagesRead,
            timeZoneID: ReadingRecord.normalizedTimeZoneID(record.timeZoneID)
        )
    }
}
