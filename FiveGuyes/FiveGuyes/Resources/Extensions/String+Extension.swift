//
//  String+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

//import Foundation

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
}
