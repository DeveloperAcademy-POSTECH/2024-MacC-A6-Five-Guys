//
//  PageCountParserTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

@testable import FiveGuyes
import Testing

@Suite("PageCountParser 테스트")
struct PageCountParserTests {
    @Test("첫 아라비아 숫자 묶음을 페이지 수로 해석한다")
    func parsesDocumentedFormats() {
        let cases: [(value: String, expected: Int?)] = [
            ("332", 332),
            ("784 p.", 784),
            ("[130] p.", 130),
            ("252, 64 p.", 252),
            ("xiii, 345 p.", 345),
            ("230페이지 내외", 230),
            ("", nil),
            ("없음", nil),
            ("0", nil)
        ]

        for testCase in cases {
            #expect(PageCountParser.parse(testCase.value) == testCase.expected)
        }
    }
}
