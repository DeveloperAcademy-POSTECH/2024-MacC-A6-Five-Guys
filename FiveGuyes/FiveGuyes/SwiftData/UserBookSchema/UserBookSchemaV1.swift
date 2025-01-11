//
//  UserBookSchemaV1.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

enum UserBookSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
        
    static var models: [any PersistentModel.Type] {
        [UserBook.self]
    }
}

extension UserBookSchemaV1 {
    @Model
    final class UserBook {
        @Attribute(.unique) var id = UUID()
        var book: SDBookDetails
        
        var readingRecords: [String: ReadingRecord] = [:] // Keyed by formatted date strings
        
        // 계산 로직을 더 편하게 하기 위해 마지막으로 읽은 날의 결과를 따로 저장합니다.
        var lastReadDate: Date? // 마지막 읽은 날짜
        var lastPagesRead: Int = 0 // 마지막으로 읽은 페이지 수
        
        var completionReview = ""
        var isCompleted: Bool = false  // 현재 읽는 중인지 완독한 책인지 표시
        
        init(book: SDBookDetails) {
            self.book = book
        }
    }
}
