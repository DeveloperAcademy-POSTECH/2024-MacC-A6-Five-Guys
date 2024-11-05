//
//  APIStore.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Combine
import Foundation

class APIStore {
    
    private var apiKey: String
    
    init() {
           guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
               fatalError("API 키를 로드하지 못했습니다.")
           }
           self.apiKey = key
           print("Loaded API Key: \(apiKey)")
       }
    private let searchBaseUrl = "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx"
    private let lookupBaseUrl = "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx"
    
    func fetchBooks(query: String) -> AnyPublisher<[Book], Error> {
        let urlString = "\(searchBaseUrl)?ttbkey=\(apiKey)&Query=\(query)&MaxResults=10&Output=js&Version=20131101"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: BookResponse.self, decoder: JSONDecoder())
            .map { $0.item }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchBookDetails(isbn: String) -> AnyPublisher<Int, Error> {
            let urlString = "\(lookupBaseUrl)?ttbkey=\(apiKey)&itemIdType=ISBN13&ItemId=\(isbn)&output=js&Version=20131101&OptResult=itemPage"
            
            guard let url = URL(string: urlString) else {
                return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
            }
            
            return URLSession.shared.dataTaskPublisher(for: url)
                .map { $0.data }
                .decode(type: BookDetailResponse.self, decoder: JSONDecoder())
                .map { response in
                    response.item?.first?.subInfo?.itemPage ?? 0 
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
}
