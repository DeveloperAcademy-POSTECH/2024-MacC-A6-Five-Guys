//
//  UserSettingsProtocol.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

import Foundation

protocol UserSettingsProtocol: AnyObject {
    var startPage: Int { get set }
    var targetEndPage: Int { get set }
    var startDate: Date { get }
    var targetEndDate: Date { get set }
    var nonReadingDays: [Date] { get set }
}
