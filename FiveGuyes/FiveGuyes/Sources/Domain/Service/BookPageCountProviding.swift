//
//  BookPageCountProviding.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

/// ISBN-13으로 도서의 총 페이지 수를 가져온다. 외부 API 구현은 Platform에 있다.
protocol BookPageCountProviding {
    /// nil은 레코드가 없거나 쪽수 정보가 없음, throw는 호출 실패·키 누락이다.
    func fetchTotalPages(isbn13: String) async throws -> Int?
}
