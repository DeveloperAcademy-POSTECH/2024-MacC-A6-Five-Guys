//
//  ReadingRecord.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/11/24.
//

import Foundation

struct ReadingRecord: Codable, Hashable {
    var targetPages: Int   // 목표로 설정된 페이지 수
    var pagesRead: Int     // 실제 읽은 페이지 수
}
