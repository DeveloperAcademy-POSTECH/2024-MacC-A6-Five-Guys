//
//  MigrationDiagnosticLoggingTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/17/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("MigrationDiagnosticLogging 테스트")
struct MigrationDiagnosticLoggingTests {
    @Test("failure message는 stage/key/error 정보를 포함한다")
    func failureMessageContainsDiagnosticFields() {
        let message = SystemMigrationDiagnosticLogger.failureMessage(
            stage: .prewarm,
            migrationKeyScope: "com.test.scope",
            error: StubMigrationError(),
            didMutate: nil
        )

        #expect(message.contains("migration_failure"))
        #expect(message.contains("stage=prewarm"))
        #expect(message.contains("key=com.test.scope"))
        #expect(message.contains("didMutate=unknown"))
        #expect(message.contains("errorType=StubMigrationError"))
        #expect(message.contains("message=stub failure"))
    }

    @Test("didMutate 플래그는 true/false로 문자열화된다")
    func failureMessageContainsMutationFlag() {
        let trueMessage = SystemMigrationDiagnosticLogger.failureMessage(
            stage: .recordKeyMigration,
            migrationKeyScope: "record.scope",
            error: StubMigrationError(),
            didMutate: true
        )
        let falseMessage = SystemMigrationDiagnosticLogger.failureMessage(
            stage: .settingsBackfill,
            migrationKeyScope: "settings.scope",
            error: StubMigrationError(),
            didMutate: false
        )

        #expect(trueMessage.contains("didMutate=true"))
        #expect(falseMessage.contains("didMutate=false"))
    }
}

private struct StubMigrationError: LocalizedError {
    var errorDescription: String? {
        "stub failure"
    }
}
