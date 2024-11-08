//
//  CompletionCalendarView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/6/24.
//

import SwiftUI
// 둘 다 눌려있는 상태에서 또 누르면 리셋?
// 중간을 누르면 뭘 움직여?
// 그냥 리셋시키는게 가장 편할 듯
// TODO: 현재 기준으로 이전 날짜는 선택 안되게 하기

struct CompletionCalendarView: View {
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var currentMonth: Date = Date()
    
    @State var totalPages: String = ""
    
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 M월"
        return formatter
    }()
    
    var body: some View {
        let title = bookSettingInputModel.selectedBook?.title ?? ""
        
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("<\(title)>\(title.subjectParticle())")
                    .lineLimit(1) // 제목이 길어지면 줄바꿈 허용
                
                HStack(spacing: 8) {
                    Text("총")
                    
                    HStack(spacing: 2) {
                        TextField("", text: $totalPages)
                            .keyboardType(.numberPad)
                            .font(.system(size: 20, weight: .medium))
                            .fixedSize()
                            .background {
                                RoundedRectangle(cornerRadius: 7)
                                    .foregroundColor(.clear)
                                    .frame(height: 30) // 텍스트 필드 높이 지정
                            }
                        
                        Image(systemName: "pencil") // 원하는 이미지로 변경
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        
                    }
                    .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                    .padding(.horizontal, 8) // 텍스트 필드와 이미지 주변 패딩
                    .padding(.vertical, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(Color(red: 0.93, green: 0.97, blue: 0.95))
                    }
                    
                    Text("쪽이에요")
                    
                    Spacer()
                }
                Text("목표기간을 선택해주세요")
            }
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.black)
            .padding(.bottom, 11)
            .padding(.horizontal, 20)
            
            weekdayHeader()
            
            Divider()
                .padding(.bottom, 20)
            
            calendarScrollView()
            
            Divider()
                .padding(.bottom, 14)
            
            if keyboardObserver.keyboardIsVisible {
                
                Button {
                    bookSettingInputModel.totalPages = totalPages
                    bookSettingInputModel.nextPage()
                    
                } label: {
                    Text("다음")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.07, green: 0.87, blue: 0.54))
                        .foregroundStyle(.white)
                    
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            } else {
                nextButton()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    nextButtomAction()
                } label: {
                    Text("완료")
                        .foregroundColor(!(selectedStartDate == nil || selectedEndDate == nil) ?
                                         Color(red: 0.03, green: 0.68, blue: 0.41)
                                         : Color(red: 0.84, green: 0.84, blue: 0.84))
                }
                .disabled(selectedStartDate == nil || selectedEndDate == nil)
            }
        }

        .onAppear {
            totalPages = bookSettingInputModel.totalPages
        }
    }
    
    private func weekdayHeader() -> some View {
        HStack(spacing: 20) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.3))
            }
        }
        .padding(.bottom, 12)
    }
    
    private func calendarScrollView() -> some View {
        ScrollView {
            VStack(spacing: 35) {
                ForEach(0..<12, id: \.self) { monthOffset in
                    let monthDate = Calendar.current.date(byAdding: .month, value: monthOffset, to: currentMonth)!
                    
                    let daysInMonth = self.getDaysInMonth(for: monthDate)
                    
                    let adjustedDays = self.adjustDaysForMonth(monthDate: monthDate, daysInMonth: daysInMonth)
                    
                    VStack(spacing: 0) {
                        Text(monthFormatter.string(from: monthDate))
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.bottom, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 16) {
                            ForEach(adjustedDays.indices, id: \.self) { index in
                                if let date = adjustedDays[index] {
                                    // 날짜가 현재 달에 속하고, 오늘 또는 선택된 날짜인 경우에만 셀 표시
                                    dateCell(for: date)
                                } else {
                                    Color.clear.frame(width: 44, height: 44)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 466)
    }

    private func dateCell(for date: Date) -> some View {
        let isSelectedDay = isDaySelected(for: date)
        let isBetweenSelectedDays = isBetweenSelectedDays(for: date)
        
        return ZStack {
            if isBetweenSelectedDays {
                Rectangle()
                    .fill(Color.green.opacity(0.2))
                    .frame(height: 44)
            } else if isSelectedDay {
                dateSelectionRectangle(for: date)
            }
            
            dateText(for: date, isSelectedDay: isSelectedDay)
                        .onTapGesture {
                            handleDateSelection(for: date)
                        }
        }
    }

    private func dateText(for date: Date, isSelectedDay: Bool) -> some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .frame(width: 44, height: 44)
            .background(
                isSelectedDay ? Color.green : Color.clear
            )
            .foregroundColor(
                isSelectedDay ? .white : .secondary
            )
            .font(
                isSelectedDay ? .system(size: 24, weight: .semibold) : .system(size: 16)
            )
            .cornerRadius(26)
    }

    // 선택된 날짜 범위에 색칠 처리
    private func dateSelectionRectangle(for date: Date) -> some View {
        HStack(spacing: 0) {
            // 선택된 시작 날짜
            if let start = selectedStartDate, date == start {
                Spacer()
                Rectangle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 28, height: 44)
            }
            // 선택된 종료 날짜
            else if let end = selectedEndDate, date == end {
                Rectangle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 28, height: 44)
                Spacer()
            }
            // 시작 날짜와 종료 날짜 사이에 있는 날짜들
            else if let start = selectedStartDate, let end = selectedEndDate, date > start, date < end {
                Rectangle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
            }
        }
    }

    // 날짜 선택 처리
    private func handleDateSelection(for date: Date) {
        let startOfDay = date // 날짜만 고려하고 시간은 무시

        if selectedStartDate == nil && selectedEndDate == nil {
            selectedStartDate = startOfDay
        } else if selectedStartDate == startOfDay {
            selectedStartDate = nil
        } else if selectedEndDate == startOfDay {
            selectedEndDate = nil
        } else if let endDate = selectedEndDate, startOfDay <= endDate {
            selectedStartDate = startOfDay
        } else if let startDate = selectedStartDate, startOfDay >= startDate {
            selectedEndDate = startOfDay
        }
        
        // 선택된 날짜를 전달할 때는 하루 더하기
        if let startDate = selectedStartDate {
            guard let adjustedStartDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) else { return }
            print("Adjusted Start Date: \(String(describing: adjustedStartDate))")
        }
        if let endDate = selectedEndDate {
            guard let adjustedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate) else { return }
            print("Adjusted End Date: \(String(describing: adjustedEndDate))")
        }
    }

    // 날짜가 범위 내에 있는지 확인
    private func isBetweenSelectedDays(for date: Date) -> Bool {
        guard let start = selectedStartDate, let end = selectedEndDate else { return false }
        return date > start && date < end
    }
    
    // 날짜가 선택된 날짜인지 확인
    private func isDaySelected(for date: Date) -> Bool {
        return date == selectedStartDate || date == selectedEndDate
    }
    
    // 달의 첫 날짜와 일들을 일요일 기준으로 맞추는 함수
    private func adjustDaysForMonth(monthDate: Date, daysInMonth: [Date]) -> [Date?] {
        let calendar = Calendar.current
        let weekdayOfFirstDay = calendar.component(.weekday, from: monthDate.startOfMonth())
        
        // 첫날이 어떤 요일에 해당하는지, 1이 일요일인 것을 기준으로 계산
        let adjustedWeekdayOfFirstDay = weekdayOfFirstDay - 1 // 일요일을 0으로 하기 위해 -1
        let shiftDays = adjustedWeekdayOfFirstDay >= 0 ? adjustedWeekdayOfFirstDay : 6
        
        // 날짜 배열 생성, shiftDays만큼 빈 공간을 채운 후, 날짜 배열을 추가
        let adjustedDays = Array(repeating: nil, count: shiftDays) + daysInMonth
        return adjustedDays
    }

    // 날짜 계산
    private func getDaysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        
        return range.compactMap { day -> Date? in
            let components = calendar.dateComponents([.year, .month], from: date)
            
            let adjustedDate = calendar.date(bySetting: .day, value: day, of: calendar.date(from: components)!)
            
            return adjustedDate.flatMap { calendar.startOfDay(for: $0) }
        }
    }
    
    // 다음 버튼
    private func nextButton() -> some View {
        Button {
            // TODO: 쉬는 날 소거 캘린더로 가기
            
            // TODO: 우선 처음과 끝만 선택하고 넘어가기
            nextButtomAction()
            
        } label: {
            Text("다음")
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
    }
    
    private func nextButtomAction() {
        bookSettingInputModel.startData = selectedStartDate
        bookSettingInputModel.endData = selectedEndDate
        
        bookSettingInputModel.nextPage()
    }
}

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
}
