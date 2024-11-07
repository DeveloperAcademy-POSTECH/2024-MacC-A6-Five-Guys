//
//  APIStore.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Foundation

class APIStore {
    
    private var apiKey: String
    
    init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            fatalError("API 키를 로드하지 못했습니다.")
        }
        self.apiKey = key
    }
    
    private let searchBaseUrl = "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx"
    private let lookupBaseUrl = "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx"
    
    func fetchBooks(query: String) async throws -> [Book] {
        let urlString = "\(searchBaseUrl)?ttbkey=\(apiKey)&Query=\(query)&MaxResults=10&Output=js&Version=20131101"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
        return bookResponse.item
    }
    
    func fetchBookTotalPages(isbn: String) async throws -> Int {
        let urlString = "\(lookupBaseUrl)?ttbkey=\(apiKey)&itemIdType=ISBN13&ItemId=\(isbn)&output=js&Version=20131101&OptResult=itemPage"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        print(data)
        let bookDetailResponse = try JSONDecoder().decode(BookDetailResponse.self, from: data)
        print(bookDetailResponse)
        print(bookDetailResponse.item?.first?.subInfo?.itemPage)
        return bookDetailResponse.item?.first?.subInfo?.itemPage ?? 0
    }
}
