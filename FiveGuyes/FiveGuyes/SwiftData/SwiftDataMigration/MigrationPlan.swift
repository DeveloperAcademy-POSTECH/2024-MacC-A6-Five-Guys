//
//  MigrationPlan.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

import SwiftData

actor MigrationPlan: SchemaMigrationPlan {
    typealias UserBookV1 = UserBookSchemaV1.UserBook
    typealias UserBookV2 = UserBookSchemaV2.UserBookV2
    
    static var schemas: [any VersionedSchema.Type] {
        [UserBookSchemaV1.self, UserBookSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    private static var userBookV2: [UserBookV2] = []
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: UserBookSchemaV1.self,
        toVersion: UserBookSchemaV2.self) { context in
            let userBooks = try context.fetch(FetchDescriptor<UserBookV1>())
            
            userBookV2 = userBooks.map { .init(from: $0) }
        } didMigrate: { context in
            userBookV2.forEach { context.insert($0)}
            
            try context.save()
        }
}
