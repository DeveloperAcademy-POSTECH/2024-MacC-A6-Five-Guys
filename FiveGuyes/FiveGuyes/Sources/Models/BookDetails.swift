//
//  BookModel.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import Foundation

struct BookDetails {
    let title: String
    let author: String
    let totalPages: Int
    let startDate: Date
    let targetEndDate: Date
    var nonReadingDays: [Date]
}

struct CurrentBook {
    var details: BookDetails
    var currentPage: Int
    var dailyTargets: [Date: Int]
}

struct CompletedBook {
    var details: BookDetails
    var completedDate: Date
}

// BookDetails 더미 데이터
extension BookDetails {
    static func dummyBookDetails1() -> BookDetails {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return BookDetails(
            title: "Swift Programming Basics",
            author: "John Doe",
            totalPages: 300,
            startDate: dateFormatter.date(from: "2024-01-01")!,
            targetEndDate: dateFormatter.date(from: "2024-02-01")!,
            nonReadingDays: [
                dateFormatter.date(from: "2024-01-07")!,
                dateFormatter.date(from: "2024-01-14")!,
                dateFormatter.date(from: "2024-01-21")!
            ]
        )
    }
    
    static func dummyBookDetails2() -> BookDetails {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return BookDetails(
            title: "Advanced iOS Development",
            author: "Jane Smith",
            totalPages: 450,
            startDate: dateFormatter.date(from: "2023-11-01")!,
            targetEndDate: dateFormatter.date(from: "2023-12-01")!,
            nonReadingDays: [
                dateFormatter.date(from: "2023-11-10")!,
                dateFormatter.date(from: "2023-11-17")!
            ]
        )
    }
    
    static func dummyBookDetails3() -> BookDetails {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return BookDetails(
            title: "UI/UX Design Principles",
            author: "Alex Johnson",
            totalPages: 200,
            startDate: dateFormatter.date(from: "2023-10-01")!,
            targetEndDate: dateFormatter.date(from: "2023-10-15")!,
            nonReadingDays: [
                dateFormatter.date(from: "2023-10-05")!
            ]
        )
    }
}

// CurrentBook 더미 데이터
extension CurrentBook {
    static func dummyCurrentBook() -> CurrentBook {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return CurrentBook(
            details: BookDetails.dummyBookDetails1(),
            currentPage: 150,
            dailyTargets: [
                dateFormatter.date(from: "2024-01-01")!: 100,
                dateFormatter.date(from: "2024-01-02")!: 100,
                dateFormatter.date(from: "2024-01-03")!: 100
            ]
        )
    }
}
