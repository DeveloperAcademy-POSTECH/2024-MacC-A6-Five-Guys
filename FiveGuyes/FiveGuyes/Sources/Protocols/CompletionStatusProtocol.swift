//
//  CompletionStatusProtocol.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

protocol CompletionStatusProtocol {
    var isCompleted: Bool { get set }
    var completionReview: String { get set }
    
    mutating func markAsCompleted(review: String)
    mutating func updateCompletionReview(reveiw: String)
}
