//
//  DataFormat.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/11/24.
//

import Foundation
import ImageIO

class DateFormatter {
    static func extractImageDate(from properties: [String: Any]) -> Date? {
        guard let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            print("❌ DateUtility/extractImageDate: No EXIF date found")
            return nil
        }

        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }

    static func formatDate(from date: Date) -> String {
        let dateFormatter = Foundation.DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        return dateFormatter.string(from: date)
    }
}
