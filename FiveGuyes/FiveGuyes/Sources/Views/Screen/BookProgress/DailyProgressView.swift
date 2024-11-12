//
//  DailyProgressView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftData
import SwiftUI

struct DailyProgressView: View {
    @State private var pagesToReadToday: Int = 0
    @State private var showAlert = false
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    let alertText = "전체쪽수를 초과해서 작성했어요!"
    let alertMessage = "끝까지 읽은 게 맞나요?"
    
    private var today: Date {
        // TODO: today가 전날로 나와서 일단 하루 더함
        Date()
    }
    let readingScheduleCalculator = ReadingScheduleCalculator()
    
    @FocusState private var isTextTextFieldFocused: Bool
    
    var body: some View {
        // TODO: 더미 지우기
        let userBook = currentlyReadingBooks.first ?? UserBook.dummyUserBook
        var book = userBook.book
        let isTodayCompletionDate = book.targetEndDate == today
        
        VStack(spacing: 0) {
            HStack {
                Text(isTodayCompletionDate ? "오늘은 <\(book.title)>\(book.title.postPositionParticle()) 완독하는\n마지막 날이에요"
                     : "지금까지 읽은 쪽수를\n알려주세요")
                .font(.system(size: 22, weight: .semibold))
                Spacer()
            }
            .padding(.top, 25)
            .padding(.bottom, 107)
            .padding(.horizontal, 20)
            
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
            .padding(.horizontal, 20)
            
            Spacer()
            
            if isTextTextFieldFocused {
                Button {
                    if pagesToReadToday > book.totalPages {
                        showAlert = true
                    } else if isTodayCompletionDate && pagesToReadToday < book.totalPages {
                        // 마지막 날이지만 완독하지 못한 경우, 날짜를 하루 늘리고 재조정
                        //                        book.targetEndDate = book.targetEndDate.addDaysInUTC(1)
                        // TODO: utc기중으로 바꾸기
                        book.targetEndDate = book.targetEndDate.addDays(1)
                        
                        readingScheduleCalculator.updateReadingProgress(for: userBook, pagesRead: pagesToReadToday, from: today)
                        navigationCoordinator.popToRoot()
                    } else {
                        // 오늘 할당량 기록
                        readingScheduleCalculator.updateReadingProgress(for: userBook, pagesRead: pagesToReadToday, from: today)
                        
                        if pagesToReadToday != book.totalPages {
                            navigationCoordinator.popToRoot()
                        } else {
                            // 완독한 경우
                            // TODO:  완독 날짜 변경은 최종 저장할 때 수정하기
                            navigationCoordinator.push(.completionCelebration)
                        }
                    }
                    
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
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertText),
                message: Text(alertMessage),
                primaryButton: .cancel(Text("다시 작성하기")) {
                    // "다시 작성하기" 로직 (입력값 초기화)
                    pagesToReadToday = 0
                    isTextTextFieldFocused = true
                },
                secondaryButton: .default(Text("확인")) {
                    // "확인" 버튼 로직 (총 페이지로 수정 및 완독 기록)
                    pagesToReadToday = book.totalPages
                    readingScheduleCalculator.updateReadingProgress(for: userBook, pagesRead: book.totalPages, from: today)
                    navigationCoordinator.push(.completionCelebration)
                }
            )
        }
        .navigationTitle("오늘 독서 현황 기록하기")
        .navigationBarTitleDisplayMode(.inline)
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
