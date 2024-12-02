//
//  UserSettings.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
final class UserSettings: UserSettingsProtocol {
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
