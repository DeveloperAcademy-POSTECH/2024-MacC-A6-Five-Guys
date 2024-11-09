//
//  DailyProgressView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftUI

struct DailyProgressView: View {
    @State private var pagesToReadToday: Int = 0
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(UserLibrary.self) var uerLibrary: UserLibrary
    
    private var today: Date {
        // TODO: today가 전날로 나와서 일단 하루 더함
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }
    let readingScheduleCalculator = ReadingScheduleCalculator()
    
    @FocusState private var isTextTextFieldFocused: Bool
    
    var body: some View {
        // TODO: 더미 지우기
        let userBook = uerLibrary.currentReadingBook ?? UserBook.dummyUserBook
        let book = userBook.book
        let isTodayCompletionDate = book.targetEndDate == today
        
        VStack(spacing: 0) {
            HStack {
                Text(isTodayCompletionDate ? "오늘은 <\(book.title)>를 완독하는\n마지막 날이에요"
                     : "지금까지 읽은 쪽수를\n알려주세요")
                .font(.system(size: 22, weight: .semibold))
                Spacer()
            }
            .padding(.top, 25)
            .padding(.bottom, 107)
            
            HStack {
                Spacer()
                
                TextField("", value: $pagesToReadToday, format: .number)
                    .frame(width: 180, height: 68)
                    .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                    .cornerRadius(16)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, weight: .semibold))
                    .tint(Color.black)
                    .focused($isTextTextFieldFocused)
                
                Text("쪽")
                    .padding(.top, 20)
                    .font(.system(size: 24, weight: .semibold))
                Spacer()
            }
            
            Spacer()
            
            if isTextTextFieldFocused {
                Button {
                    // 오늘 할당량 기록
                    readingScheduleCalculator.updateReadingProgress(for: userBook, pagesRead: pagesToReadToday, from: today)
                    
                    print(userBook.readingRecords)
                    navigationCoordinator.popToRoot()
                    
                } label: {
                    Text("완료")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.07, green: 0.87, blue: 0.54))
                        .foregroundStyle(.white)
                    
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
        }
        .padding(.horizontal, 20)
        .navigationTitle("오늘 독서 현황 기록하기")
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .onAppear {
            print("🐯🐯🐯🐯🐯: \(today)")
            
            if let readingRecord = readingScheduleCalculator.getReadingRecord(for: userBook, for: today) {
                pagesToReadToday = readingRecord.targetPages
            }
            
            isTextTextFieldFocused = true
        }
    }
}
