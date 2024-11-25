//
//  UserSettings.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation

struct UserSettings: UserSettingsProtocol, Codable {
    var startPage: Int
    var targetEndPage: Int
    var startDate: Date
    var targetEndDate: Date
    var nonReadingDays: [Date]
}
