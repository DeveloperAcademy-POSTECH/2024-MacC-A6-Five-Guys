//
//  SDCompletionStatus.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//
import SwiftData

@Model
// 이 타입은 완독 결과(완독 여부, 소감)만 따로 관리합니다.
// 완독 처리를 분리해 두면 수정 흐름이 단순해집니다.
final class CompletionStatus {
    // 앱은 이 값으로 어떤 화면을 보여줄지 고릅니다.
    // 값이 어긋나면 완독 화면 분기가 잘못 열릴 수 있습니다.
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
