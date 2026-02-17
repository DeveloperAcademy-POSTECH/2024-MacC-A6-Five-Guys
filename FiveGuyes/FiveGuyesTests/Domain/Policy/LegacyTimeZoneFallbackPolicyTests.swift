//
//  LegacyTimeZoneFallbackPolicyTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/17/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("LegacyTimeZoneFallbackPolicy 테스트")
struct LegacyTimeZoneFallbackPolicyTests {
    @Test("두 fallback 타임존 상수는 유효한 TimeZone identifier여야 한다")
    func fallbackIdentifiersAreValidTimeZones() {
        let recordTimeZone = TimeZone(identifier: LegacyTimeZoneFallbackPolicy.readingRecordDefaultTimeZoneID)
        let settingsTimeZone = TimeZone(identifier: LegacyTimeZoneFallbackPolicy.settingsDateKeyFallbackTimeZoneID)

        #expect(recordTimeZone != nil)
        #expect(settingsTimeZone != nil)
    }

    @Test("현재 정책에서 레코드와 설정 fallback 타임존 값은 동일하다")
    func fallbackIdentifiersAreCurrentlySame() {
        #expect(
            LegacyTimeZoneFallbackPolicy.readingRecordDefaultTimeZoneID
                == LegacyTimeZoneFallbackPolicy.settingsDateKeyFallbackTimeZoneID
        )
        #expect(LegacyTimeZoneFallbackPolicy.readingRecordDefaultTimeZoneID == "Asia/Seoul")
    }
}
