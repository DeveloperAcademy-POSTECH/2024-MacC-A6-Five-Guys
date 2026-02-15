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
           guard let date = toReadingDateKey()?.toDate(calendar: .app) else {
               return self
           }

           let year = Calendar.app.component(.year, from: date)
           return "\(year)"
       }
    // (지은이) 제거
    func removingParenthesesContent() -> String {
         return self.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
             .trimmingCharacters(in: .whitespacesAndNewlines)
     }
}

extension String {
    /// 날짜 키 파싱은 `ReadingDateKey` 단일 경로를 사용합니다.
    /// 포맷 안정성(`en_US_POSIX`)과 정책 시간대(`Calendar.app.timeZone`)를 함께 보장하기 위함입니다.
    func toReadingDateKey() -> ReadingDateKey? {
        ReadingDateKey(parsing: self, calendar: .app)
    }

    /// 문자열을 `yyyy-MM-dd` 형식으로 `Date` 객체로 변환합니다.
    /// 기존 호출부 호환을 위해 메서드 이름은 유지하고, 내부 구현만 `ReadingDateKey`를 재사용합니다.
    /// - Returns: 변환된 `Date` 객체 또는 변환이 실패한 경우 `nil`.
    func toDate() -> Date? {
        toReadingDateKey()?.toDate(calendar: .app)
    }
}
