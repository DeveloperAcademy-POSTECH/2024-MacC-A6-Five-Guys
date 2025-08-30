//
//  MainHomeView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct MainHomeView: View {
    typealias SDUserBook = UserBookSchemaV2.UserBookV2
    
    // Derived UI State
    private enum HomeState {
        case reading(book: SDUserBook)
        case hasCompletedNoReading
        case noCompletedNoReading
    }
    
    let notificationManager = NotificationManager()
    let mainAlertMessage = "삭제 후에는 복원할 수 없어요"
    let today = Date().adjustedDate()
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(\.modelContext) private var modelContext
    
    @State private var topSafeAreaInset: CGFloat = 0
    @State private var showReadingBookAlert = false
    @State private var showCompletionAlert = false
    
    @State private var activeBookID: UUID?
    @State private var selectedBookIndex: Int?

    @Query(
        filter: #Predicate<SDUserBook> {
            $0.completionStatus.isCompleted == false
        }
    )
    private var SDReadingBooks: [SDUserBook]
    
    // 완독한 책을 가져오는 쿼리
    @Query(
        filter: #Predicate<SDUserBook> { $0.completionStatus.isCompleted == true }
    )
    private var SDCompletedBooks: [SDUserBook]

    private var readingBooks: [FGUserBook] {
        SDReadingBooks.map { $0.toFGUserBook() }
    }

    private var selectedBook: SDUserBook? {
        if let selectedBookIndex, !SDReadingBooks.isEmpty && selectedBookIndex < SDReadingBooks.count {
            return SDReadingBooks[selectedBookIndex]
        }
        return nil
    }
    
    private var homeState: HomeState {
        if let selectedBook {
            return .reading(book: selectedBook)
        }
        if let firstReading = SDReadingBooks.first {
            return .reading(book: firstReading)
        }
        return SDCompletedBooks.isEmpty ? .noCompletedNoReading : .hasCompletedNoReading
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        notiButton {
                            // 독서 종료일이 제일 가까운 책을 기준으로 노티를 설정합니다.
                            navigationCoordinator.push(.notiSetting(book: SDReadingBooks.first))
                        }
                    }
                    .padding(.bottom, 12)
                    .padding(.trailing, 20)
                    
                    HStack(alignment: .top, spacing: 20) {
                        titleView()
                        
                        Spacer()
                        
                        if !SDReadingBooks.isEmpty { // 읽고 있는 책이 있는 경우
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
                                    title: Text(getMainAlertText(book: selectedBook))
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
                    
                    // Home Main Section
                    homeMainSection
                        .padding(.bottom, 12)
                        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 4)
                        .id(navigationCoordinator.getViewReloadTrigger())
                        .onAppear(perform: navigationCoordinator.reloadView)
                    
                    HStack(spacing: 16) {
                        calendarFullScreenButton
                            .frame(width: 107)
                        
                        bookActionButton
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 20)
                }
                
                CompletedBooksView(completedBooks: SDCompletedBooks)
            }
            .padding(.top, topSafeAreaInset)
        }
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .background(alignment: .top) {
            LinearGradient(colors: [Color(red: 0.81, green: 1, blue: 0.77), Color.Fills.white], startPoint: .top, endPoint: .bottom)
                .frame(height: 561)
                .ignoresSafeArea(edges: .top)
        }
        .onChange(of: activeBookID) {
            if let activeBookID {
                selectedBookIndex = SDReadingBooks.firstIndex(where: { $0.id == activeBookID })
            } else {
                selectedBookIndex = nil
            }
        }
        .onAppear {
            calculateTopSafeAreaInset()
            reassignReadingSchedules()
        }
        .task {
            trackScreen()
            initializeActiveBookID()
            
            // 독서 종료일이 제일 가까운 책을 기준으로 노티를 설정합니다.
            if let currentReadingBook = SDReadingBooks.first {
                await notificationManager.setupAllNotifications(currentReadingBook)
            } else {
                print("노티 설정 실패 ❗️❗️❗️")
            }
        }
    }
    
    // MARK: - View Property & Function
    
    private var titleText: String {
        switch homeState {
        case .reading(let book):
            return "\(book.bookMetaData.title)"
        case .noCompletedNoReading:
            return "반가워요,\n저와 함께 완독을 시작해볼까요?"
        case .hasCompletedNoReading:
            return "완독의 즐거움,\n다음 책에서도 이어나가볼까요?"
        }
    }
    
    private var bookActionText: String {
        switch homeState {
        case .reading:
            return "오늘 독서 현황 기록하기"
        case .noCompletedNoReading:
            return "완독할 책 등록하기"
        case .hasCompletedNoReading:
            return "완독할 책 추가하기"
        }
    }
    
    private func performBookAction() {
        switch homeState {
        case .reading(let book):
            navigationCoordinator.push(.dailyProgress(book: book))
        case .noCompletedNoReading, .hasCompletedNoReading:
            navigationCoordinator.push(.bookSettingsManager)
        }
    }
    
    private func titleView() -> some View {
        VStack(alignment: .leading) {
            Text(titleText)
        }
        .lineLimit(2)
        .frame(height: 110, alignment: .topLeading)
        .fontStyle(.title1, weight: .semibold)
        .foregroundStyle(Color.Labels.primaryBlack1)
    }
    
    @ViewBuilder
    private var homeMainSection: some View {
        VStack {
            Spacer()
            
            switch homeState {
            case .reading:
                ReadingBooksCarousel(
                    readingBooks: readingBooks,
                    today: today,
                    activeID: $activeBookID
                )
            case .hasCompletedNoReading:
                    EmptyReadingBooksView(state: .hasCompleted)
                    .padding(.horizontal, 24)
            case .noCompletedNoReading:
                    EmptyReadingBooksView(state: .noCompleted)
                    .padding(.horizontal, 24)
            }
        }
        .frame(height: 275)
    }
    
    private func notiButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "bell")
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 50)
                .tint(Color.Labels.primaryBlack1)
        }
    }
    
    private var calendarFullScreenButton: some View {
        let isReadingBookAvailable = !SDReadingBooks.isEmpty
        let backgroundColor = isReadingBookAvailable ? Color.Fills.white : Color.Fills.lightGreen
        let opacity = isReadingBookAvailable ? 1 : 0.2
        
        return Button {
            if let selectedBook {
                navigationCoordinator.push(.totalCalendar(book: selectedBook.toFGUserBook()))
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
    
    private var bookActionButton: some View {
        let isReadingBookAvailable = SDReadingBooks.first != nil
        
        return Button {
            performBookAction()
        } label: {
            Text(bookActionText)
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
    private func getMainAlertText(book: SDUserBook?) -> String {
        if let book {
            let title = book.bookMetaData.title
            return "현재 읽고 있는 <\(title)>\(title.postPositionParticle()) 책장에서 삭제할까요?"
        } else {
            return ""
        }
    }
    
    private func getRemainingDays(book: SDUserBook) -> Int {
        let redingDateCalculator = ReadingDateCalculator()
        let remainingReadingDays = try? redingDateCalculator.calculateValidReadingDays(
            startDate: Date().adjustedDate(),
            endDate: book.userSettings.targetEndDate,
            excludedDates: book.userSettings.nonReadingDays)
        
        return remainingReadingDays ?? 0
    }
    
    private func deleteBook(at index: Int) {
        guard index < SDReadingBooks.count else { return }
        
        let bookToDelete = SDReadingBooks[index]
        modelContext.delete(bookToDelete)
        
        // 데이터 저장
        do {
            try modelContext.save()
        } catch {
            print("데이터 저장 중 오류 발생: \(error.localizedDescription)")
        }
        
        // 삭제 후 인덱스 업데이트
        if SDReadingBooks.isEmpty {
            selectedBookIndex = nil
        } else if index >= SDReadingBooks.count {
            selectedBookIndex = SDReadingBooks.count - 1
        }
    }
    
    private func trackScreen() {
        if SDReadingBooks.isEmpty {
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
        guard !SDReadingBooks.isEmpty else { return }
        
        let readingScheduleCalculator = ReadingScheduleCalculator()
        
        for book in SDReadingBooks {
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
    
    private func initializeActiveBookID() {
        activeBookID = SDReadingBooks.first?.id
    }
}
