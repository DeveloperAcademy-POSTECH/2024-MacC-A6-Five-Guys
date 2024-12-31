//
//  ReadingDateCalculatorTests.swift
//  ReadingDateCalculatorTests
//
//  Created by zaehorang on 12/26/24.
//

import Testing
import Foundation

@testable import FiveGuyes

struct ReadingDateCalculatorTests {
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    func date(from string: String) -> Date {
        guard let date = dateFormatter.date(from: string) else {
            fatalError("Invalid date format: \(string)")
        }
        return date
    }
    
    // MARK: - Test calculateDaysBetween
    @Test
    func testCalculateDaysBetween_ValidDates() async throws {
        let startDate = date(from: "2024-12-20 08:00:00")
        let endDate = date(from: "2024-12-26 22:30:00")
        
        let days = try ReadingDateCalculator.calculateDaysBetween(startDate: startDate, endDate: endDate)
        
        #expect(days == 7)
    }
    
    @Test
    func testCalculateDaysBetween_SameDateWithDifferentTimes() async throws {
        let startDate = date(from: "2024-12-20 00:00:00")
        let endDate = date(from: "2024-12-20 23:59:59")
        
        let days = try ReadingDateCalculator.calculateDaysBetween(startDate: startDate, endDate: endDate)
        #expect(days == 1)
    }
    
    
    // MARK: - Test calculateValidDayCount
    @Test
    func testCalculateValidDayCount_NoExcludedDatesWithTimes() async throws {
        let startDate = date(from: "2024-12-20 10:00:00")
        let endDate = date(from: "2024-12-26 22:00:00")
        let excludedDates: [Date] = []
        
        let validDays = try ReadingDateCalculator.calculateValidReadingDays(
            startDate: startDate,
            endDate: endDate,
            excludedDates: excludedDates
        )
        
        #expect(validDays == 7)
    }
    
    @Test
    func testCalculateValidDayCount_WithExcludedDatesAndTimes() async throws {
        let startDate = date(from: "2024-12-20 10:00:00")
        let endDate = date(from: "2024-12-26 22:00:00")
        let excludedDates = [
            date(from: "2024-12-22 08:00:00"),
            date(from: "2024-12-19 08:00:00"),
            date(from: "2024-12-24 18:00:00"),
            date(from: "2024-12-29 18:00:00")
        ]
        
        let validDays = try ReadingDateCalculator.calculateValidReadingDays(
            startDate: startDate,
            endDate: endDate,
            excludedDates: excludedDates
        )
        
        #expect(validDays == 5)
    }
    
    @Test
    func testCalculateValidDayCount_AllDatesExcludedWithTimes() async throws {
        let startDate = date(from: "2024-12-20 10:00:00")
        let endDate = date(from: "2024-12-26 22:00:00")
        let excludedDates = [
            date(from: "2024-12-20 11:00:00"),
            date(from: "2024-12-21 12:00:00"),
            date(from: "2024-12-22 13:00:00"),
            date(from: "2024-12-23 14:00:00"),
            date(from: "2024-12-24 15:00:00"),
            date(from: "2024-12-25 16:00:00"),
            date(from: "2024-12-26 17:00:00")
        ]
        
        let validDays = try ReadingDateCalculator.calculateValidReadingDays(
            startDate: startDate,
            endDate: endDate,
            excludedDates: excludedDates
        )
        
        #expect(validDays == 0)
    }

}
