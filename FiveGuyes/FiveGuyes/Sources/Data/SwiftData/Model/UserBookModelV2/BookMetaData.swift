//
//  SDBookMetaData.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import SwiftData

@Model
final class BookMetaData: BookMetaDataProtocol {
    var title: String
    var author: String
    var coverURL: String?
    var totalPages: Int
    
    init(title: String, author: String, coverURL: String?, totalPages: Int) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
    }
}
