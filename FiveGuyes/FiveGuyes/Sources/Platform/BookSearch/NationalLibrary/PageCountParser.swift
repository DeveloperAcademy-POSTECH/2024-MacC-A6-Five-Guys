//
//  PageCountParser.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

enum PageCountParser {
    static func parse(_ value: String) -> Int? {
        let digits = value.unicodeScalars
            .drop { !(48...57).contains($0.value) }
            .prefix { (48...57).contains($0.value) }

        guard !digits.isEmpty,
              let pageCount = Int(String(String.UnicodeScalarView(digits))),
              pageCount > 0 else {
            return nil
        }

        return pageCount
    }
}
