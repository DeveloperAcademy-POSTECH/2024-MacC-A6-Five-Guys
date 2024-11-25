//
//  BookMetaData.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation

struct BookMetaData: BookMetaDataProtocol, Codable {
    let title: String
    let author: String
    let coverURL: String?
    let totalPages: Int
}
