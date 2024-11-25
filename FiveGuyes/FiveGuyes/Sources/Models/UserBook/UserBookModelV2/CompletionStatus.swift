//
//  CompletionStatus.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

struct CompletionStatus: CompletionStatusProtocol, Codable {
    var isCompleted: Bool = false
    var completionReview: String = ""
    
    mutating func markAsCompleted(review: String) {
        isCompleted = true
        completionReview = review
    }
    
    mutating func updateCompletionReview(reveiw: String) {
        completionReview = reveiw
    }
}
