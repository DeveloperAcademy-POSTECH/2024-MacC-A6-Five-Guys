//
//  SDCompletionStatus.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//
import SwiftData

@Model
final class SDCompletionStatus: CompletionStatusProtocol {
    var isCompleted: Bool
    var completionReview: String
    
    init(isCompleted: Bool = false, completionReview: String = "") {
        self.isCompleted = isCompleted
        self.completionReview = completionReview
    }
    
    func markAsCompleted(review: String) {
        self.isCompleted = true
        self.completionReview = review
    }
    
    func updateCompletionReview(review: String) {
        self.completionReview = review
    }
}
