//
//  BookSearchProviding.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-15.
//

/// 도서 검색·페이지 조회가 던지는 오류.
enum BookSearchError: Error, Equatable {
    /// 인증 정보가 없다. 검색에서는 설정 안내 알림으로 이어진다(spec A10).
    case missingAPIKey(setting: String)
    /// 그 밖의 모든 실패. 검색은 결과를 바꾸지 않고, 페이지 조회는 0쪽으로 처리한다(spec A9, B7).
    case failed
}

/// 검색어로 도서 목록을 가져온다. 외부 API 구현은 Platform에 있다.
protocol BookSearchProviding {
    func searchBooks(query: String) async throws -> [BookSearchItem]
}
