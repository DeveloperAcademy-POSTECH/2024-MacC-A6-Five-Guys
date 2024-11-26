//
//  CompletionStatusProtocol.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

protocol CompletionStatusProtocol {
    var isCompleted: Bool { get set }
    var completionReview: String { get set }
    
    /// 책을 완독 상태로 바꾸고, 완독 리뷰를 저장하는 메서드
    func markAsCompleted(review: String)
    /// 완독 리뷰를 업데이트하는 메서드
    func updateCompletionReview(review: String)
}
