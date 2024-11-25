//
//  NotificationType.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/12/24.
//

import Foundation

enum NotificationType {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    case morning(readingBook: UserBook)
    case night(readingBook: UserBook)
    
    func descriptionContent() -> (title: String, body: String) {
        switch self {
        case .morning(let readingBook):
            let title = "오늘의 한입, 준비됐나요?"
            let body = "오늘은 \(readingBook.findNextReadingPagesPerDay())페이지만 읽으면 돼요 멍멍!"
            return (title, body)
            
        case .night:
            let title = "오늘의 한입독서를 놓치고 계신가요?"
            let body = "오늘 완독하지 않았어요!\n완독이가 물어버릴거에요 🥎 왕왕"
            return (title, body)
        }
    }
    
    func dateContent() -> Date? {
        switch self {
        case .morning(let readingBook), .night(let readingBook):
            return readingBook.findNextReadingDay()
        }
    }
    
    func timeContent() -> (hour: Int, minute: Int) {
        switch self {
        case .morning:
            return (9, 0)
        case .night:
            return (21, 0)
        }
    }
    
    /// 고유 identifier 생성 메서드
    func identifier() -> String {
        switch self {
        case .morning(let readingBook):
            return "\(readingBook.book.title)-morning"
        case .night(let readingBook):
            return "\(readingBook.book.title)-night"
        }
    }    
}
