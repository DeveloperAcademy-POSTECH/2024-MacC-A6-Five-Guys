//
//  TotalCalendarViewBasic.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/7/24.
//

import SwiftUI

struct CustomCalendarView: View {
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack {
            // Header with Month and Year
            header
            
            // Weekday Labels (Sunday to Saturday)
            weekdayLabels
            
            // Calendar Days
            dayGrid
        }
        .padding()
    }
    
    private var header: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            
            Text(monthYearString(for: currentMonth))
                .font(.title2)
                .bold()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }
    
    private var weekdayLabels: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var dayGrid: some View {
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            let (daysInMonth, startDayOfWeek) = getDateInfo()
            let totalCells = startDayOfWeek + daysInMonth
            
            ForEach(0..<totalCells, id: \.self) { index in
                if index < startDayOfWeek {
                    // Display an empty cell before the start of the month
                    Text("")
                        .frame(width: 40, height: 40)
                } else {
                    // Calculate the day number
                    let day = index - startDayOfWeek + 1
                    VStack {
                        Text("\(day)")
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(isToday(day: day) ? Color.blue : Color.clear))
                            .foregroundColor(isToday(day: day) ? .white : .black)
                    }
                    .frame(width: 40, height: 40) // Ensure consistent sizing for each day cell
                }
            }
        }
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func getDateInfo() -> (daysInMonth: Int, startDayOfWeek: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        
        // Get the first day of the current month
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return (0, 0)
        }
        
        let daysInMonth = range.count
        let startDayOfWeek = calendar.component(.weekday, from: firstOfMonth) - 1
        print(startDayOfWeek)
        return (daysInMonth, startDayOfWeek)
        
    }
    
    private func isToday(day: Int) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(today, equalTo: currentMonth, toGranularity: .month) &&
        calendar.component(.day, from: today) == day
    }
}
