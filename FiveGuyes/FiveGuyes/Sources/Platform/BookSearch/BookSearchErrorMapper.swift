//
//  BookSearchErrorMapper.swift
//  FiveGuyes
//
//  Created by Codex on 2026-10-08.
//

import FGNetwork

enum BookSearchErrorMapper {
    static func map(_ error: APIKeyError) -> BookSearchError {
        switch error {
        case let .missing(name):
            .missingAPIKey(setting: name)
        }
    }

    static func map(_ error: HTTPClientError) -> BookSearchError {
        switch error {
        case .cancelled:
            .cancelled
        case .transport:
            .network
        case .invalidRequest, .invalidResponse, .unexpectedStatus, .decoding:
            .invalidResponse
        }
    }
}
