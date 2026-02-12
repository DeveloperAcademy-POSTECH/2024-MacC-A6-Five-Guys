//
//  DailyProgressView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftUI

struct DailyProgressView: View {
    @State private var pagesToReadToday: Int = 0
    @State private var showAlert = false
    @State private var isSubmitting = false
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(AppDependencies.self) private var appDependencies
    
    private let alertText = "전체쪽수를 초과해서 작성했어요!"
    private let alertMessage = "끝까지 읽은 게 맞나요?"
    
    private let adjustedToday = Date().adjustedDate()
    
    @FocusState private var isTextTextFieldFocused: Bool
    
    let userBook: FGUserBook
    
    var body: some View {
        let title = userBook.bookMetaData.title
        let targetEndPage = userBook.userSettings.targetEndPage
        let targetEndDate = userBook.userSettings.targetEndDate
        
        let isTodayCompletionDate = Calendar.app.isDate(adjustedToday, inSameDayAs: targetEndDate)
        
        VStack(spacing: 0) {
            HStack {
                Text(isTodayCompletionDate ? "오늘은 <\(title)>\(title.postPositionParticle()) 완독하는\n마지막 날이에요"
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
                    if pagesToReadToday > targetEndPage {
                        // 최종 목표보다 더 큰 페이지를 입력하면
                        showAlert = true
                        return
                    }

                    submitReading()
                } label: {
                    Text("완료")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.Colors.green1)
                        .foregroundStyle(Color.Fills.white)
                    
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .disabled(isSubmitting)
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
                    pagesToReadToday = targetEndPage
                    submitReading()
                }
            )
        }
        .navigationTitle("오늘 독서 현황 기록하기")
        .customNavigationBackButton()
        .onAppear {
            // ⏰
            if let readingRecord = userBook.readingProgress.getDailyReadingRecord(for: adjustedToday) {
                pagesToReadToday = readingRecord.targetPages
            }
            
            isTextTextFieldFocused = true
        }
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.dailyProgress.setTracking()
        }
    }

    @MainActor
    private func submitReading() {
        guard !isSubmitting else { return }
        isSubmitting = true

        let pagesRead = pagesToReadToday
        Task {
            do {
                let result = try await appDependencies.bookManagementService.recordReading(
                    bookId: userBook.id,
                    pagesRead: pagesRead,
                    readDate: adjustedToday
                )

                await MainActor.run {
                    isSubmitting = false
                    handleRecordResult(result)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
                print("독서 기록 저장 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func handleRecordResult(_ result: RecordReadingResult) {
        switch result {
        case .recorded:
            navigationCoordinator.popToRoot()
        case .dateExtended:
            navigationCoordinator.popToRoot()
        case .completed(let updatedBook):
            navigationCoordinator.push(.completionCelebration(book: updatedBook))
        case .exceedsTarget:
            showAlert = true
        }
    }
}
