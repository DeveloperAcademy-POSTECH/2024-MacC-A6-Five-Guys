//
//  LegacyTimeZoneFallbackPolicy.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/17/26.
//

import Foundation

/// legacy 데이터 호환을 위한 fallback 타임존 상수의 단일 소유권입니다.
///
/// 값은 현재 동일하지만 의미(레코드 fallback vs 설정 key fallback)를 분리해
/// 전환 종료 시 독립적으로 제거/변경하기 쉽게 유지합니다.
enum LegacyTimeZoneFallbackPolicy {
    /// ReadingRecord에 `timeZoneID`가 비어 있거나 누락된 legacy 데이터의 기본값
    static let readingRecordDefaultTimeZoneID = "Asia/Seoul"

    /// Settings의 legacy Date를 DateKey로 보정할 때 사용하는 기본 타임존
    static let settingsDateKeyFallbackTimeZoneID = "Asia/Seoul"
}
