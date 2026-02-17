//
//  MigrationDiagnosticLogging.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/17/26.
//

import Foundation
import os

enum MigrationDiagnosticStage: String {
    case prewarm
    case fetch
    case settingsBackfill = "settings_backfill"
    case recordKeyMigration = "record_key_migration"
}

protocol MigrationDiagnosticLogging {
    func logFailure(
        stage: MigrationDiagnosticStage,
        migrationKeyScope: String,
        error: any Error,
        didMutate: Bool?
    )
}

struct SystemMigrationDiagnosticLogger: MigrationDiagnosticLogging {
    private let logger: Logger

    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.zaehorang.FiveGuyes",
        category: String = "migration"
    ) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    func logFailure(
        stage: MigrationDiagnosticStage,
        migrationKeyScope: String,
        error: any Error,
        didMutate: Bool?
    ) {
        logger.error("\(Self.failureMessage(stage: stage, migrationKeyScope: migrationKeyScope, error: error, didMutate: didMutate), privacy: .public)")
    }

    static func failureMessage(
        stage: MigrationDiagnosticStage,
        migrationKeyScope: String,
        error: any Error,
        didMutate: Bool?
    ) -> String {
        let mutationFlag = didMutate.map(String.init(describing:)) ?? "unknown"
        return
            "migration_failure stage=\(stage.rawValue) " +
            "key=\(migrationKeyScope) " +
            "didMutate=\(mutationFlag) " +
            "errorType=\(String(describing: type(of: error))) " +
            "message=\(error.localizedDescription)"
    }
}
