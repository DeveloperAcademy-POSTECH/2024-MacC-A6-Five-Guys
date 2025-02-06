//
//  MainHomeView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct MainHomeView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(\.modelContext) private var modelContext
    
    @State private var topSafeAreaInset: CGFloat = 0
    @State private var showReadingBookAlert = false
    @State private var showCompletionAlert = false
    
    let mainAlertMessage = "삭제 후에는 복원할 수 없어요"
    private let notificationManager = NotificationManager()
    
    @Query(
        filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == false },
        sort: \UserBook.userSettings.targetEndDate) // 독서 종료 날짜를 기준으로 오름차순
    private var currentlyReadingBooks: [UserBook]
    
    @State private var activeBookID: UUID?
    @State private var selectedBookIndex: Int? = 0
    
    private var selectedBook: UserBook? {
        if let selectedBookIndex, !currentlyReadingBooks.isEmpty && selectedBookIndex < currentlyReadingBooks.count {
            return currentlyReadingBooks[selectedBookIndex]
        }
        return nil
    }
    
    var body: some View {
        let title = selectedBook?.bookMetaData.title ?? ""
        let mainAlertText = "현재 읽고 있는 <\(title)>\(title.postPositionParticle()) 책장에서 삭제할까요?"
        
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        notiButton {
                            // 독서 종료일이 제일 가까운 책을 기준으로 노티를 설정합니다.
                            navigationCoordinator.push(.notiSetting(book: currentlyReadingBooks.first))
                        }
                    }
                    .padding(.bottom, 49)
                    .padding(.trailing, 20)
                    
                    HStack(alignment: .top, spacing: 10) {
                        titleDescription(book: selectedBook)
                        
                        Spacer()
                        
                        if !currentlyReadingBooks.isEmpty { // 읽고 있는 책이 없는 경우
                            Menu {
                                ReadingDateEditButton
                                UserBookAddButton
                                DeleteReadingBookButton
                            } label: {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 22)
                                    .tint(Color.Labels.primaryBlack1)
                            }
                            .fontStyle(.body)
                            .alert(isPresented: $showReadingBookAlert) {
                                Alert(
                                    title: Text(mainAlertText)
                                        .alertFontStyle(.title3, weight: .semibold),
                                    message: Text(mainAlertMessage)
                                        .alertFontStyle(.caption1),
                                    primaryButton: .cancel(Text("취소하기")),
                                    secondaryButton: .destructive(Text("삭제")) {
                                        if let selectedBookIndex {
                                            deleteBook(at: selectedBookIndex)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                    
                    WeeklyProgressPagingSlider(readingBooks: currentlyReadingBooks, activeID: $activeBookID)
                        .padding(.bottom, 16)
                        .commonShadow()
                        .safeAreaPadding(.horizontal, 30)
                        .id(navigationCoordinator.getViewReloadTrigger())
                        .onAppear(perform: navigationCoordinator.reloadView)
                    
                    HStack(spacing: 16) {
                        calendarFullScreenButton
                            .frame(width: 107)
                        
                        mainActionButton
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 20)
                }
                
                CompletionListView()
            }
            .padding(.top, topSafeAreaInset)
        }
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .background(alignment: .top) {
            LinearGradient(colors: [Color(red: 0.81, green: 1, blue: 0.77), Color.Fills.white], startPoint: .top, endPoint: .bottom)
                .frame(height: 448)
                .ignoresSafeArea(edges: .top)
        }
        .onChange(of: activeBookID) {
            if let activeBookID {
                selectedBookIndex = currentlyReadingBooks.firstIndex(where: { $0.id == activeBookID })
            } else {
                selectedBookIndex = nil
            }
        }
        .onAppear {
            calculateTopSafeAreaInset()
            resetSelectedBookIndex()
            
            guard !currentlyReadingBooks.isEmpty else { return }
            reassignReadingSchedules()
        }
        .task {
            trackScreen()
            
            // 독서 종료일이 제일 가까운 책을 기준으로 노티를 설정합니다.
            if let currentReadingBook = currentlyReadingBooks.first {
                await notificationManager.setupAllNotifications(currentReadingBook)
            } else {
                print("노티 설정 실패 ❗️❗️❗️")
            }
        }
    }
    
    // MARK: - View Property & Function
    
    private func titleDescription(book: UserBook?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if let book {
                Text("<\(book.bookMetaData.title)>")
                    .lineLimit(2)
                Text("완독까지 \(getRemainingDays(book: book))일 남았어요!")
                    .lineLimit(1)
            } else {
                Text("환영해요!")
                Text("저와 함께 완독을 시작해볼까요?")
            }
        }
        .frame(height: 110, alignment: .topLeading)
        .fontStyle(.title1, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
    }
    
    private func notiButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "bell")
                .resizable()
                .scaledToFill()
                .frame(width: 17, height: 19)
                .tint(Color.Labels.primaryBlack1)
        }
    }
    
    private var calendarFullScreenButton: some View {
        let isReadingBookAvailable = !currentlyReadingBooks.isEmpty
        let backgroundColor = isReadingBookAvailable ? Color.Fills.white : Color.Fills.lightGreen
        let opacity = isReadingBookAvailable ? 1 : 0.2
        
        return Button {
            if let selectedBook {
                navigationCoordinator.push(.totalCalendar(book: selectedBook))
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                Text("전체")
            }
            .fontStyle(.title2, weight: .semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(Color.Labels.primaryBlack1)
            .opacity(opacity)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(backgroundColor)
            }
            .commonShadow()
            .overlay(
                isReadingBookAvailable ? nil : RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.5)
                    .stroke(Color.Separators.green, lineWidth: 1)
            )
        }
        .disabled(!isReadingBookAvailable)
    }
    
    private var mainActionButton: some View {
        let isReadingBookAvailable = currentlyReadingBooks.first != nil
        
        return Button {
            if isReadingBookAvailable, let selectedBook {
                navigationCoordinator.push(.dailyProgress(book: selectedBook))
            } else {
                navigationCoordinator.push(.bookSettingsManager)
            }
        } label: {
            Text(isReadingBookAvailable ? "오늘 독서 현황 기록하기" : "+ 완독할 책 추가하기")
                .fontStyle(.title2, weight: .semibold)
                .foregroundStyle(Color.Fills.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.Colors.green1)
                }
        }
    }
    
    private var ReadingDateEditButton: some View {
        Button {
            // 날짜 수정 화면으로 기기
            if let selectedBook {
                navigationCoordinator.push(.readingDateEdit(book: selectedBook))
            }
        } label: {
            Label("수정하기", systemImage: "pencil")
                .foregroundStyle(Color.Labels.primaryBlack1)
        }
    }
    
    private var UserBookAddButton: some View {
        Button {
            navigationCoordinator.push(.bookSettingsManager)
        } label: {
            Label("책 추가하기", systemImage: "plus")
                .foregroundStyle(Color.Labels.primaryBlack1)
        }
    }
    
    private var DeleteReadingBookButton: some View {
        Button(role: .destructive) {
            showReadingBookAlert = true
        } label: {
            Label("삭제", systemImage: "trash")
        }
    }
    
    // MARK: - Helper Method
    private func getRemainingDays(book: UserBook) -> Int {
        let redingDateCalculator = ReadingDateCalculator()
        let remainingReadingDays = try? redingDateCalculator.calculateValidReadingDays(
            startDate: Date().adjustedDate(),
            endDate: book.userSettings.targetEndDate,
            excludedDates: book.userSettings.nonReadingDays)
        
        return remainingReadingDays ?? 0
    }
    
    
    private func deleteBook(at index: Int) {
        guard index < currentlyReadingBooks.count else { return }
        
        let bookToDelete = currentlyReadingBooks[index]
        modelContext.delete(bookToDelete)
        
        // 데이터 저장
        do {
            try modelContext.save()
        } catch {
            print("데이터 저장 중 오류 발생: \(error.localizedDescription)")
        }
        
        // 삭제 후 인덱스 업데이트
        if currentlyReadingBooks.isEmpty {
            selectedBookIndex = nil
        } else if index >= currentlyReadingBooks.count {
            selectedBookIndex = currentlyReadingBooks.count - 1
        }
    }
    
    private func trackScreen() {
        if currentlyReadingBooks.isEmpty {
            Tracking.Screen.homeBeforeBookSetting.setTracking()
        } else {
            Tracking.Screen.homeAfterBookSetting.setTracking()
        }
    }
    
    private func calculateTopSafeAreaInset() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first {
            topSafeAreaInset = window.safeAreaInsets.top
        }
    }
    
    private func reassignReadingSchedules() {
        let readingScheduleCalculator = ReadingScheduleCalculator()
        
        for book in currentlyReadingBooks {
            do {
                try readingScheduleCalculator
                    .reassignPagesFromLastReadDate(
                        settings: book.userSettings,
                        progress: book.readingProgress
                    )
            } catch ReadingScheduleError.targetDatePassed {
                // 종료 날짜 초과 에러가 발생한 경우 날짜 연장 뷰로 이동
                navigationCoordinator.push(.unfinishReading(book: book))
                continue
            } catch {
                print("예상치 못한 에러 발생: \(error.localizedDescription)")
            }
        }
        
        // 데이터 저장
        do {
            try modelContext.save()
        } catch {
            print("읽기 스케줄 저장 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    private func resetSelectedBookIndex() {
        activeBookID = currentlyReadingBooks.first?.id
    }
}
