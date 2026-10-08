//
//  BookSearchErrorMapperTests.swift
//  FiveGuyesTests
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork
@testable import FiveGuyes
import Foundation
import Testing

@Suite("BookSearchErrorMapper 테스트")
struct BookSearchErrorMapperTests {
    @Test("API 키 누락 오류에 설정 이름을 보존한다")
    func mapsMissingAPIKey() {
        #expect(
            BookSearchErrorMapper.map(APIKeyError.missing(name: "KAKAO_API_KEY"))
                == .missingAPIKey(setting: "KAKAO_API_KEY")
        )
    }

    @Test("전송 오류를 네트워크 오류로 변환한다")
    func mapsTransportError() {
        #expect(
            BookSearchErrorMapper.map(HTTPClientError.transport(URLError(.notConnectedToInternet)))
                == .network
        )
    }

    @Test("취소 오류를 취소로 변환한다")
    func mapsCancellation() {
        #expect(BookSearchErrorMapper.map(HTTPClientError.cancelled) == .cancelled)
    }

    @Test("응답 처리 오류를 잘못된 응답으로 변환한다", arguments: [
        HTTPClientError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "invalid"))),
        HTTPClientError.invalidRequest,
        HTTPClientError.invalidResponse,
        HTTPClientError.unexpectedStatus(500, Data())
    ])
    func mapsResponseErrors(error: HTTPClientError) {
        #expect(BookSearchErrorMapper.map(error) == .invalidResponse)
    }
}
