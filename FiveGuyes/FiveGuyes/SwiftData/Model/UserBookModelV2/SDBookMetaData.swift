//
//  SDBookMetaData.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/25/24.
//

import Foundation
import SwiftData

@Model
final class SDBookMetaData: BookMetaDataProtocol {
    let title: String
    let author: String
    let coverURL: String?
    let totalPages: Int
    
    init(title: String, author: String, coverURL: String?, totalPages: Int) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
    }
}
