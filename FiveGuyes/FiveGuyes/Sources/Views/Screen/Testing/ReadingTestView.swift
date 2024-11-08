//
//  ReadingTestView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/7/24.
//

import SwiftUI

//MARK: - 페이지 계산 모델 테스팅을 위한 Text UI입니다.
struct ReadingTestView: View {
    @State private var readingScheduleCalculator: ReadingScheduleCalculator? = nil

    var body: some View {
        ScrollView {
            VStack {
                if let readingProgress = readingScheduleCalculator {

                        DailyReadingScheduleView(readingScheduleCalculator: readingProgress)

                } else {
                    // BookInputView로 읽기 목표 설정 화면
                    BookInputView { bookInfo in
                        readingScheduleCalculator = ReadingScheduleCalculator(bookInfo: bookInfo)
                    }
                    .navigationTitle("책 정보 입력")
                }
            }
        }
    }
}

struct BookInputView: View {
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages: String = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedDate = Date()
    
    @State private var nonReadingDays: [Date] = []
    
    var onBookInfoSubmit: (BookModel) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("총 페이지 수", text: $totalPages)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            VStack(spacing: 20) {
                Text("제외할 날짜 추가")
                    .font(.largeTitle)
                    .padding()
                
                // 제외할 날짜 선택
                DatePicker("제외할 날짜 선택", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button {
                    // TODO: 여기는 string key로 저장해야 하려나
                    if !nonReadingDays.contains(selectedDate) {
                        nonReadingDays.append(selectedDate)
                        print("추가: \(selectedDate)")
                    }
                } label: {
                    Text("제외 날짜 추가")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // 제외된 날짜 리스트 표시
                VStack {
                    ForEach(nonReadingDays, id: \.self) { date in
                        Text(date.formattedDateString())
                    }
                }
                
                Spacer()
            }
            .padding()
            
            DatePicker("읽기 시작 날짜", selection: $startDate, displayedComponents: .date)
                .padding()
            
            DatePicker("완독 목표 날짜", selection: $endDate, displayedComponents: .date)
                .padding()
            
            Button("읽기 목표 설정") {
                if let total = Int(totalPages) {
                    let bookInfo = BookModel(
                        title: title,
                        author: author,
                        totalPages: total,
                        startDate: startDate,
                        targetEndDate: endDate,
                        nonReadingDays: []
                    )
                    onBookInfoSubmit(bookInfo)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

struct DailyReadingScheduleView: View {
    @ObservedObject var readingScheduleCalculator: ReadingScheduleCalculator
    @State private var selectedDate = Date()
    @State private var pagesRead: String = ""
    
    @State private var pagesReadInput: String = ""
    let today = Calendar.current.startOfDay(for: Date())
    
    var body: some View {
        VStack(spacing: 20) {
            Text("일일 독서 목표")
                .font(.largeTitle)
                .padding()
            
            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                .padding()
            
            VStack {
                ForEach(readingScheduleCalculator.dailyTargets.keys.sorted(), id: \.self) { date in
                    HStack {
                        Text("\(date)")
                        Spacer()
                        if let record = readingScheduleCalculator.dailyTargets[date] {
                            Text("목표: \(record.targetPages) 페이지")
                            Text("읽음: \(record.pagesRead) 페이지")
                        }
                    }
                    
                }
            }
            
            Divider()
            
            TextField("오늘 읽은 페이지 입력", text: $pagesReadInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Button {
                if let pagesRead = Int(pagesReadInput) {
                    readingScheduleCalculator.updateReadingProgress(for: today, pagesRead: pagesRead)
                }
            } label: {
                Text("진행 업데이트")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
    }
}

extension Date {
    func formattedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

#Preview {
    ReadingTestView()
}
