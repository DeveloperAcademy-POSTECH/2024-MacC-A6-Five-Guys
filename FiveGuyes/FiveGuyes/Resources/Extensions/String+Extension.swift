//
//  String+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import Foundation

extension String {
    func postPositionParticle() -> String {
        guard let lastCharacter = self.last else { return "를" }
        
        // 마지막 문자의 유니코드 값 추출
        guard let unicodeValue = UnicodeScalar(String(lastCharacter))?.value else { return "를" }
        
        // 숫자인 경우
        if lastCharacter.isNumber, let lastDigit = Int(String(lastCharacter)) {
            let numbersWithFinalConsonant = [0, 1, 3, 6, 7, 8]
            return numbersWithFinalConsonant.contains(lastDigit) ? "을" : "를"
        }
        
        // 영어 문자일 경우
        if unicodeValue < 0xAC00 || unicodeValue > 0xD7A3 {
            let lastLowercased = lastCharacter.lowercased()
            let koreanConsonantAlphabets = ["l", "m", "n", "r"]
            return koreanConsonantAlphabets.contains(lastLowercased) ? "을" : "를"
        }
        
        // 한글 문자일 경우
        let finalConsonant = (unicodeValue - 0xAC00) % 28
        return finalConsonant > 0 ? "을" : "를"
    }
    
    /// 문자열의 마지막 글자(영어라면 발음)에 따라 '은' 또는 '는'을 반환
        func subjectParticle() -> String {
            guard let lastCharacter = self.last else { return "는" }
            
            guard let unicodeValue = UnicodeScalar(String(lastCharacter))?.value else { return "는" }
            
            // TODO: -숫자일때 발음확인
            
            // 영어 문자 받침 발음확인
            if unicodeValue < 0xAC00 || unicodeValue > 0xD7A3 {
                let lastLowercased = lastCharacter.lowercased()
                let koreanConsonantAlphabets = ["l", "m", "n", "r"]
                return koreanConsonantAlphabets.contains(lastLowercased) ? "은" : "는"
            }
            
            // 한글 문자 받침확인
            let finalConsonant = (unicodeValue - 0xAC00) % 28
            return finalConsonant > 0 ? "은" : "는"
        }
    
    // 년도 추출
    func extractYear() -> String {
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "yyyy-MM-dd"
           if let date = dateFormatter.date(from: self) {
               let calendar = Calendar.current
               let year = calendar.component(.year, from: date)
               return "\(year)"
           }
           return self
       }
    // (지은이) 제거
    func removingParenthesesContent() -> String {
         return self.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
             .trimmingCharacters(in: .whitespacesAndNewlines)
     }
}
