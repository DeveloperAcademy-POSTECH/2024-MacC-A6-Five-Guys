//
//  PageCountParser.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

/// CIP 기준 쪽수 문자열(`"300 p."`, `"xiii, 345 p."`)에서 총 페이지 수를 뽑는다.
enum PageCountParser {
    /// 처음 나오는 아라비아 숫자 묶음을 쪽수로 본다. 숫자가 없거나 0이면 nil(spec B5, B6).
    static func parse(_ value: String) -> Int? {
        guard let match = value.firstMatch(of: /[0-9]+/),
              let pageCount = Int(match.output),
              pageCount > 0 else {
            return nil
        }

        return pageCount
    }
}
