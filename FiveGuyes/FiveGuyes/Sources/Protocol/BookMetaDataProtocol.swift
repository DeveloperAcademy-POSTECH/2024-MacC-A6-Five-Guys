//
//  ExternalBookDataProtocol.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/24/24.
//

protocol BookMetaDataProtocol {
    var title: String { get }
    var author: String { get }
    var coverURL: String? { get }
    var totalPages: Int { get }
}
