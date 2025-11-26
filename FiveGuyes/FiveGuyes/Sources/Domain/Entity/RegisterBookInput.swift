//
//  RegisterBookInput.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-01-08.
//

import Foundation

/// 책 등록 시 필요한 입력 정보
struct RegisterBookInput {
    let bookMetaData: FGBookMetaData
    let userSettings: FGUserSetting
}
