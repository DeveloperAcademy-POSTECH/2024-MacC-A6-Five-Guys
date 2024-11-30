//
//  DailyProgressView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftData
import SwiftUI

struct DailyProgressView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @State private var pagesToReadToday: Int = 0
    @State private var showAlert = false
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @Query(filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    private let alertText = "전체쪽수를 초과해서 작성했어요!"
    private let alertMessage = "끝까지 읽은 게 맞나요?"
    
    private let notificationManager = NotificationManager()
    private let readingScheduleCalculator = ReadingScheduleCalculator()
    
    private let today = Date()
    
    @FocusState private var isTextTextFieldFocused: Bool
    
    var body: some View {
        let userBook = currentlyReadingBooks.first ?? UserBook.dummyUserBookV2
        
        let bookMetadata: BookMetaDataProtocol = userBook.bookMetaData
        let userSettings: UserSettingsProtocol = userBook.userSettings
        let readingProgress: any ReadingProgressProtocol = userBook.readingProgress
        
        let isTodayCompletionDate = Calendar.current.isDate(today, inSameDayAs: userSettings.targetEndDate)
        
        VStack(spacing: 0) {
            HStack {
                Text(isTodayCompletionDate ? "오늘은 <\(bookMetadata.title)>\(bookMetadata.title.postPositionParticle()) 완독하는\n마지막 날이에요"
                     : "지금까지 읽은 쪽수를\n알려주세요")
                .fontStyle(.title2, weight: .semibold)
                Spacer()
            }
            .padding(.top, 25)
            .padding(.bottom, 107)
            .padding(.horizontal, 20)
            
            HStack {
                Spacer()
                
                TextField("", value: $pagesToReadToday, format: .number)
                    .frame(width: 180, height: 68)
                    .background(Color.Fills.lightGreen)
                    .cornerRadius(16)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .fontStyle(.title1, weight: .semibold)
                    .tint(Color.Labels.primaryBlack1)
                    .focused($isTextTextFieldFocused)
                
                Text("쪽")
                    .padding(.top, 20)
                    .fontStyle(.title1, weight: .semibold)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            if isTextTextFieldFocused {
                Button {
                    if pagesToReadToday > userSettings.targetEndPage {
                        showAlert = true
                        return
                    } else if isTodayCompletionDate && pagesToReadToday < userSettings.targetEndPage {
                        
                        userSettings.targetEndDate = userSettings.targetEndDate.addDays(1)
                        
                        readingScheduleCalculator.updateReadingProgress(
                            for: userSettings,
                            progress: readingProgress,
                            pagesRead: pagesToReadToday, from: today
                        )
                        
                        // 노티 세팅하기
                        Task {
                            await notificationManager.setupAllNotifications(userBook)
                        }
                        
                        navigationCoordinator.popToRoot()
                    } else {
                        // 오늘 할당량 기록
                        readingScheduleCalculator.updateReadingProgress(
                            for: userSettings,
                            progress: readingProgress,
                            pagesRead: pagesToReadToday,
                            from: today
                        )
                        
                        // 노티 세팅하기
                        Task {
                            await notificationManager.setupAllNotifications(userBook)
                        }
                        
                        if pagesToReadToday != userSettings.targetEndPage {
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
                        .background(Color.Colors.green2)
                        .foregroundStyle(Color.Fills.white)
                    
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
        }
        .alert(isPresented: $showAlert) {
            // TODO: 커스텀스타일 적용 어려워서 임의로 스타일 지정함 확인필요
            Alert(
                title: Text(alertText)
                    .alertFontStyle(.title3, weight: .semibold),
                message: Text(alertMessage)
                    .alertFontStyle(.caption1),
                primaryButton: .cancel(Text("다시 작성하기")) {
                    // "다시 작성하기" 로직 (입력값 초기화)
                    pagesToReadToday = 0
                    isTextTextFieldFocused = true
                },
                secondaryButton: .default(Text("확인")) {
                    // "확인" 버튼 로직 (최종 타켓 페이지로 수정 및 완독 기록)
                    pagesToReadToday = userSettings.targetEndPage
                    
                    readingScheduleCalculator.updateReadingProgress(for: userSettings, progress: readingProgress, pagesRead: pagesToReadToday, from: today)
                    
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
            // ⏰
            if let readingRecord = readingProgress.getAdjustedReadingRecord(for: today) {
                pagesToReadToday = readingRecord.targetPages
            }
            
            isTextTextFieldFocused = true
        }
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.dailyProgress.setTracking()
        }
    }
}
