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

        guard let unicodeValue = UnicodeScalar(String(lastCharacter))?.value else { return "를" }

        if lastCharacter.isNumber, let lastDigit = Int(String(lastCharacter)) {
            let numbersWithFinalConsonant = [0, 1, 3, 6, 7, 8]
            return numbersWithFinalConsonant.contains(lastDigit) ? "을" : "를"
        }

        if unicodeValue < 0xAC00 || unicodeValue > 0xD7A3 {
            let lastLowercased = lastCharacter.lowercased()
            let koreanConsonantAlphabets = ["l", "m", "n", "r"]
            return koreanConsonantAlphabets.contains(lastLowercased) ? "을" : "를"
        }

        let finalConsonant = (unicodeValue - 0xAC00) % 28
        return finalConsonant > 0 ? "을" : "를"
    }

    /// 문자열의 마지막 글자(영어라면 발음)에 따라 '은' 또는 '는'을 반환
        func subjectParticle() -> String {
            guard let lastCharacter = self.last else { return "는" }

            guard let unicodeValue = UnicodeScalar(String(lastCharacter))?.value else { return "는" }

            if unicodeValue < 0xAC00 || unicodeValue > 0xD7A3 {
                let lastLowercased = lastCharacter.lowercased()
                let koreanConsonantAlphabets = ["l", "m", "n", "r"]
                return koreanConsonantAlphabets.contains(lastLowercased) ? "은" : "는"
            }

            let finalConsonant = (unicodeValue - 0xAC00) % 28
            return finalConsonant > 0 ? "은" : "는"
        }

    func extractYear() -> String {
           guard let date = toReadingDateKey()?.toDate(calendar: .app) else {
               return self
           }

           let year = Calendar.app.component(.year, from: date)
           return "\(year)"
       }
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
}
