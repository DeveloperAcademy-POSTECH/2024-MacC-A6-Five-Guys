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
    
    private let adjustedToday = Date().adjustedDate()
    
    @FocusState private var isTextTextFieldFocused: Bool
    
    var body: some View {
        // 책이 있을 때만 해당 뷰로 올 수 있기 때문에 우선 강제 언래핑으로 사용
        let userBook = currentlyReadingBooks.first!
        
        let bookMetadata: BookMetaDataProtocol = userBook.bookMetaData
        let userSettings: UserSettingsProtocol = userBook.userSettings
        let readingProgress: any ReadingProgressProtocol = userBook.readingProgress
        
        let isTodayCompletionDate = Calendar.current.isDate(adjustedToday, inSameDayAs: userSettings.targetEndDate)
        
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
                        // 최종 목표보다 더 큰 페이지를 입력하면
                        showAlert = true
                        return
                    } else if isTodayCompletionDate && pagesToReadToday < userSettings.targetEndPage {
                        // 오늘이 마지막 날인데, 최종 목표를 다 읽지 못하면
                        
                        // 목표 날짜를 하루 연장 (자동 연장)
                        userSettings.targetEndDate = userSettings.targetEndDate.addDays(1)
                        
                        readingScheduleCalculator.updateReadingProgress(
                            for: userSettings,
                            progress: readingProgress,
                            pagesRead: pagesToReadToday, from: adjustedToday
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
                            from: adjustedToday
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
                        .background(Color.Colors.green1)
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
                    
                    readingScheduleCalculator.updateReadingProgress(for: userSettings, progress: readingProgress, pagesRead: pagesToReadToday, from: adjustedToday)
                    
                    navigationCoordinator.push(.completionCelebration)
                }
            )
        }
        .navigationTitle("오늘 독서 현황 기록하기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .onAppear {
            // ⏰
            if let readingRecord = readingProgress.getAdjustedReadingRecord(for: adjustedToday) {
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
