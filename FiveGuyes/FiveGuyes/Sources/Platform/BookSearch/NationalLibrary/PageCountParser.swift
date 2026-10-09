//
//  PageCountParser.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

enum PageCountParser {
    static func parse(_ value: String) -> Int? {
        guard let match = value.firstMatch(of: /[0-9]+/),
              let pageCount = Int(match.output),
              pageCount > 0 else {
            return nil
        }

        return pageCount
    }
}
