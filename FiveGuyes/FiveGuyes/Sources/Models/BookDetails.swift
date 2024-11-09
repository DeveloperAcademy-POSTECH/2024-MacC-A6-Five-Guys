//
//  BookModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

@Observable
final class BookDetails {
    let title: String
    let author: String
    let coverURL: String?
    let totalPages: Int
    
    let startDate: Date
    let targetEndDate: Date
    
    var nonReadingDays: [Date]

    init(title: String, author: String, coverURL: String? = nil, totalPages: Int, startDate: Date, targetEndDate: Date, nonReadingDays: [Date] = []) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
        self.startDate = startDate
        self.targetEndDate = targetEndDate
        self.nonReadingDays = nonReadingDays
    }
}

struct ReadingRecord {
    var targetPages: Int   // 목표로 설정된 페이지 수
    var pagesRead: Int     // 실제 읽은 페이지 수
}

@Observable
final class UserBook {
    var book: BookDetails
    var readingRecord: [String: ReadingRecord] = [:] // Keyed by formatted date strings
    
    init(book: BookDetails) {
        self.book = book
    }
}

@Observable
final class UserLibrary {
    var currentReadingBook: UserBook?
    var completedBooks: [BookDetails] = []
    
}


//// BookDetails 더미 데이터
//extension BookDetails {
//    static func dummyBookDetails1() -> BookDetails {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        
//        return BookDetails(
//            title: "Swift Programming Basics",
//            author: "John Doe",
//            totalPages: 300,
//            startDate: dateFormatter.date(from: "2024-01-01")!,
//            targetEndDate: dateFormatter.date(from: "2024-02-01")!,
//            nonReadingDays: [
//                dateFormatter.date(from: "2024-01-07")!,
//                dateFormatter.date(from: "2024-01-14")!,
//                dateFormatter.date(from: "2024-01-21")!
//            ]
//        )
//    }
//    
//    static func dummyBookDetails2() -> BookDetails {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        
//        return BookDetails(
//            title: "Advanced iOS Development",
//            author: "Jane Smith",
//            totalPages: 450,
//            startDate: dateFormatter.date(from: "2023-11-01")!,
//            targetEndDate: dateFormatter.date(from: "2023-12-01")!,
//            nonReadingDays: [
//                dateFormatter.date(from: "2023-11-10")!,
//                dateFormatter.date(from: "2023-11-17")!
//            ]
//        )
//    }
//    
//    static func dummyBookDetails3() -> BookDetails {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        
//        return BookDetails(
//            title: "UI/UX Design Principles",
//            author: "Alex Johnson",
//            totalPages: 200,
//            startDate: dateFormatter.date(from: "2023-10-01")!,
//            targetEndDate: dateFormatter.date(from: "2023-10-15")!,
//            nonReadingDays: [
//                dateFormatter.date(from: "2023-10-05")!
//            ]
//        )
//    }
//}
//
//// CurrentBook 더미 데이터
//extension CurrentBook {
//    static func dummyCurrentBook() -> CurrentBook {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        
//        return CurrentBook(
//            details: BookDetails.dummyBookDetails1(),
//            currentPage: 150,
//            dailyTargets: [
//                dateFormatter.date(from: "2024-01-01")!: 100,
//                dateFormatter.date(from: "2024-01-02")!: 100,
//                dateFormatter.date(from: "2024-01-03")!: 100
//            ]
//        )
//    }
//}
