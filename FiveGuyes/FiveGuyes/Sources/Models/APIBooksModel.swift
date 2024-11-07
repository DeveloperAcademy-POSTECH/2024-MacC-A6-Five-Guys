//
//  APIBook.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Foundation

struct Book: Identifiable, Codable, Equatable {
    let id = UUID()
    // var 로 변경시 에러발생함
    let title: String
    let author: String
    let cover: String?
    let publisher: String
    let isbn13: String
    let pubDate: String
}

struct BookResponse: Codable {
    let item: [Book]
}

struct BookDetailResponse: Codable {
    let item: [BookDetail]?
}

struct BookDetail: Codable {
    let subInfo: SubInfo?
}

struct SubInfo: Codable {
    let itemPage: Int?
}
