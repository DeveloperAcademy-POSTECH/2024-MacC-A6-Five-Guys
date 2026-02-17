//
//  SDUserSettings.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var startPage: Int
    var targetEndPage: Int
    var startDate: Date
    var targetEndDate: Date
    var nonReadingDays: [Date]
    var startDateKey: String?
    var targetEndDateKey: String?
    var nonReadingDayKeys: [String]?

    init(
        startPage: Int,
        targetEndPage: Int,
        startDate: Date,
        targetEndDate: Date,
        nonReadingDays: [Date],
        startDateKey: String? = nil,
        targetEndDateKey: String? = nil,
        nonReadingDayKeys: [String]? = nil
    ) {
        self.startPage = startPage
        self.targetEndPage = targetEndPage
        self.startDate = startDate
        self.targetEndDate = targetEndDate
        self.nonReadingDays = nonReadingDays
        self.startDateKey = startDateKey
        self.targetEndDateKey = targetEndDateKey
        self.nonReadingDayKeys = nonReadingDayKeys
    }
}
