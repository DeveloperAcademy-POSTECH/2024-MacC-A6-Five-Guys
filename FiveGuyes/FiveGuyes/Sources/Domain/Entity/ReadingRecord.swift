//
//  ReadingRecord.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/11/24.
//

import Foundation

struct ReadingRecord: Codable, Hashable {
    // Legacy 레코드(필드 없음)와 빈 값은 모두 이 정책 기본 타임존으로 수렴시킨다.
    static let legacyDefaultTimeZoneID = "Asia/Seoul"

    var targetPages: Int   // 목표로 설정된 페이지 수
    var pagesRead: Int     // 실제 읽은 페이지 수
    var timeZoneID: String // 기록 생성/갱신 시점의 타임존 ID

    init(
        targetPages: Int,
        pagesRead: Int,
        timeZoneID: String = ReadingRecord.legacyDefaultTimeZoneID
    ) {
        self.targetPages = targetPages
        self.pagesRead = pagesRead
        self.timeZoneID = Self.normalizedTimeZoneID(timeZoneID)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        targetPages = try container.decode(Int.self, forKey: .targetPages)
        pagesRead = try container.decode(Int.self, forKey: .pagesRead)
        let decodedTimeZoneID = try container.decodeIfPresent(String.self, forKey: .timeZoneID)
        timeZoneID = Self.normalizedTimeZoneID(decodedTimeZoneID)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(targetPages, forKey: .targetPages)
        try container.encode(pagesRead, forKey: .pagesRead)
        try container.encode(Self.normalizedTimeZoneID(timeZoneID), forKey: .timeZoneID)
    }

    private enum CodingKeys: String, CodingKey {
        case targetPages
        case pagesRead
        case timeZoneID
    }

    /// 레코드 타임존 식별자 정규화 정책의 단일 진입점이다.
    static func normalizedTimeZoneID(_ timeZoneID: String?) -> String {
        guard let rawTimeZoneID = timeZoneID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawTimeZoneID.isEmpty else {
            // forward-only 전환 전 데이터와 비정상 입력을 안전하게 처리한다.
            return legacyDefaultTimeZoneID
        }
        return rawTimeZoneID
    }

    /// 동일 키 충돌 시 기존 값(lhs)을 우선하되, legacy 기본값만 가진 경우 rhs의 비-legacy 값을 채택한다.
    static func mergedTimeZoneID(lhs: String?, rhs: String?) -> String {
        let lhsNormalized = normalizedTimeZoneID(lhs)
        let rhsNormalized = normalizedTimeZoneID(rhs)

        if lhsNormalized == legacyDefaultTimeZoneID,
           rhsNormalized != legacyDefaultTimeZoneID {
            return rhsNormalized
        }

        return lhsNormalized
    }
}
