//
//  SDBookMetaData.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import SwiftData

@Model
// 이 타입은 책 자체 정보만 보관합니다.
// 읽기 진행 정보와 분리해 두면, 화면과 저장 로직이 덜 헷갈립니다.
final class BookMetaData {
    // 이후 계산 로직은 이 값들을 기준으로 목표를 만듭니다.
    // 값이 틀리면 일정 계산도 같이 틀어집니다.
    var title: String
    var author: String
    var coverURL: String?
    var totalPages: Int
    
    init(title: String, author: String, coverURL: String?, totalPages: Int) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
    }
}
