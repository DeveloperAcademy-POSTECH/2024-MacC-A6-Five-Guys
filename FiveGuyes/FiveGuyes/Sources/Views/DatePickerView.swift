//
//  DatePickerView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import SwiftUI

struct DatePickerView: View {
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var currentDate: Date = Date()
    private let calendar = Calendar.current
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 M월"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private var daysInMonth: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentDate) else { return [] }
        return monthRange.compactMap {
            calendar.date(from: DateComponents(year: calendar.component(.year, from: currentDate), month: calendar.component(.month, from: currentDate), day: $0))
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                Text(monthFormatter.string(from: currentDate))
                    .fontWeight(.semibold)
                    .font(.system(size: 20))
                Spacer()
                HStack(spacing: 30) {
                    createMonthButton(action: moveToPreviousMonth, imageName: "chevron.left")
                    createMonthButton(action: moveToNextMonth, imageName: "chevron.right")
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 10) {
                ForEach(daysInMonth, id: \.self) { date in
                    let isInRange = (date >= startDate && date <= endDate)
                    let isStartDate = calendar.isDate(date, inSameDayAs: startDate)
                    let isEndDate = calendar.isDate(date, inSameDayAs: endDate)
                    
                    Text(dayFormatter.string(from: date))
                        .font(.system(size: 20))
                        .fontWeight(isStartDate || isEndDate ? .semibold : .regular)
                        .frame(width: 44, height: 44)
                        .background(isStartDate || isEndDate ? Color(red: 0.5, green: 0.37, blue: 1) : (isInRange ? Color(red: 0.5, green: 0.37, blue: 1).opacity(0.3) : Color.clear))
                        .foregroundColor(isStartDate || isEndDate ? .white : .black)
                        .clipShape(Circle())
                        .onTapGesture {
                            handleDateSelection(date)
                        }
                }
            }
            
            Button {
                // TODO: 기간 선택 후 로직 작성
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    Text("선택 완료")
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(width: 361, height: 60, alignment: .center)
                .background((startDate != endDate) ? Color(red: 0.5, green: 0.37, blue: 1) : Color.gray)
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func createMonthButton(action: @escaping () -> Void, imageName: String) -> some View {
        Button(action: action) {
            Image(systemName: imageName)
                .resizable()
                .frame(width: 10, height: 18, alignment: .top)
                .foregroundColor(.primeryPurple)
        }
    }
    
    private func moveToPreviousMonth() {
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = previousMonth
        }
    }
    
    private func moveToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = nextMonth
        }
    }
    
    private func handleDateSelection(_ date: Date) {
        if startDate == endDate {
            startDate = date
        } else {
            if date < startDate {
                endDate = startDate
                startDate = date
            } else {
                endDate = date
            }
        }
        
        if startDate != endDate {
            currentDate = startDate
        }
    }
}

#Preview {
    DatePickerView()
}
