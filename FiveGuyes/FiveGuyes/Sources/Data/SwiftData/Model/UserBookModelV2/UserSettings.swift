//
//  SDUserSettings.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
// 사용자가 정한 시작/끝 페이지와 날짜를 한곳에 모아 둔 타입입니다.
// 계획 계산은 이 묶음 값을 읽어서 진행됩니다.
final class UserSettings {
    // 하루 목표 페이지는 이 설정에서 계산됩니다.
    // 그래서 여기 값이 바뀌면 전체 계획도 함께 바뀝니다.
    var startPage: Int
    var targetEndPage: Int
    var startDate: Date
    var targetEndDate: Date
    var nonReadingDays: [Date]
    
    init(startPage: Int, targetEndPage: Int, startDate: Date, targetEndDate: Date, nonReadingDays: [Date]) {
        self.startPage = startPage
        self.targetEndPage = targetEndPage
        self.startDate = startDate
        self.targetEndDate = targetEndDate
        self.nonReadingDays = nonReadingDays
    }
    
    func changeStartDate(for date: Date) {
        self.startDate = date
    }
}
