//
//  CalendarWeekdayHeader.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/5/25.
//

import SwiftUI

struct CalendarWeekdayHeader: View {
    let calendarCalculator: CalendarCalculator
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(calendarCalculator.getWeekdayHeaders(), id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .fontStyle(.caption1, weight: .semibold)
                    .foregroundStyle(Color.Labels.tertiaryBlack3)
            }
        }
        .padding(.horizontal, 23)
    }
}

#Preview {
    CalendarWeekdayHeader(calendarCalculator: CalendarCalculator())
}
