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
        print("Loaded API Key: \(apiKey)")
    }
    
    private let searchBaseUrl = "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx"
    private let lookupBaseUrl = "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx"
    
    func fetchBooks(query: String, completion: @escaping (Result<[Book], Error>) -> Void) {
        let urlString = "\(searchBaseUrl)?ttbkey=\(apiKey)&Query=\(query)&MaxResults=10&Output=js&Version=20131101"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }
                
                do {
                    let bookResponse = try JSONDecoder().decode(BookResponse.self, from: data)
                    completion(.success(bookResponse.item))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func fetchBookDetails(isbn: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let urlString = "\(lookupBaseUrl)?ttbkey=\(apiKey)&itemIdType=ISBN13&ItemId=\(isbn)&output=js&Version=20131101&OptResult=itemPage"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(URLError(.badServerResponse)))
                    return
                }
                
                do {
                    let bookDetailResponse = try JSONDecoder().decode(BookDetailResponse.self, from: data)
                    let pageCount = bookDetailResponse.item?.first?.subInfo?.itemPage ?? 0
                    completion(.success(pageCount))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}
