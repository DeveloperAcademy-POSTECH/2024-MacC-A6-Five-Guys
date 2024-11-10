//
//  MainHomeView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct MainHomeView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(\.modelContext) private var modelContext
    
    @State private var topSafeAreaInset: CGFloat = 0
    @State private var showAlert = false
    
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]
    
    let alertMessage = "삭제 후에는 복원할 수 없어요"
    
    var body: some View {
        let title = currentlyReadingBooks.first?.book.title ?? "제목 없음"
        let alertText = "현재 읽고 있는 <\(title)>\(title.postPositionParticle()) 책장에서 삭제할까요?"
        
        ScrollView {
            ZStack(alignment: .top) {
                Color.green.opacity(0.2)
                    .frame(height: 448)
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        notiButton {
                            navigationCoordinator.push(.empthNoti)
                        }
                    }
                    .padding(.bottom, 42)
                    
                    HStack(alignment: .top) {
                        titleDescription
                            .padding(.bottom, 40)
                        Spacer()
                        
                        if !currentlyReadingBooks.isEmpty {
                            Button {
                                showAlert = true
                            } label: {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 22)
                                    .tint(Color(red: 0.44, green: 0.44, blue: 0.44))
                            }
                        }
                    }
                    
                    ZStack(alignment: .top) {
                        
                        WeeklyReadingProgressView()
                            .padding(.top, 153)
                        
                        if let currentReadingBook = currentlyReadingBooks.first,
                           let coverURL = currentReadingBook.book.coverURL,
                           let url = URL(string: coverURL) {
                            // TODO: 옆에 책 제목, 저자 text 추가하기
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 104, height: 161)
                                    .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Rectangle()
                                .foregroundColor(.white)
                                .frame(width: 104, height: 161)
                                .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                        }
                        
                    }
                    .padding(.bottom, 16)
                    
                    HStack(spacing: 16) {
                        calendarFullScreenButton
                            .frame(width: 107)
                        
                        mainActionButton
                    }
                    .padding(.bottom, 40)
                    
                    CompletionListView()
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, topSafeAreaInset)
            }
        }
        .background(.white)
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertText),
                message: Text(alertMessage),
                primaryButton: .cancel(Text("취소하기")),
                secondaryButton: .destructive(Text("삭제")) {
                    if let currentReadingBook = currentlyReadingBooks.first {
                                            // SwiftData 컨텍스트에서 삭제 필요
                                            modelContext.delete(currentReadingBook)
                                        }
                }
            )
        }
        .onAppear {
            // 상단 안전 영역 값 계산
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first {
                topSafeAreaInset = window.safeAreaInsets.top
            }
            
            if let currentReadingBook = currentlyReadingBooks.first {
                let readingScheduleCalculator = ReadingScheduleCalculator()
                print("🌝🌝🌝🌝🌝 재할당!!")
                readingScheduleCalculator.reassignPagesFromLastReadDate(for: currentReadingBook)
            }
        }
    }
    
    private var titleDescription: some View {
        let readingScheduleCalculator = ReadingScheduleCalculator()
        
        return HStack {
            if let currentReadingBook = currentlyReadingBooks.first {
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("<\(currentReadingBook.book.title)>")
                        .lineLimit(2)
                    Text("완독까지 \(readingScheduleCalculator.calculateRemainingReadingDays(for: currentReadingBook))일 남았어요!")
                }
                
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("환영해요!")
                    Text("저와 함께 완독을 시작해볼까요?")
                }
            }
            
            Spacer()
        }
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(.black)
    }
    
    private func notiButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "bell")
                .resizable()
                .scaledToFill()
                .frame(width: 17, height: 19)
                .tint(.black)
        }
    }
    
    private var calendarFullScreenButton: some View {
        let isReadingBookAvailable = currentlyReadingBooks.first != nil
        let backgroundColor = isReadingBookAvailable ? Color.white : Color(red: 0.98, green: 1, blue: 0.99)
        let opacity = isReadingBookAvailable ? 1 : 0.2
        
        return Button {
                navigationCoordinator.push(.totalCalendar)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                Text("전체")
            }
            .font(.system(size: 20, weight: .medium))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            .opacity(opacity)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(backgroundColor)
            }
            .shadow(color: isReadingBookAvailable ? Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25) : .clear, radius: 2, x: 0, y: 4)
            .overlay(
                isReadingBookAvailable ? nil : RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.5)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!isReadingBookAvailable)
    }
    
    private var mainActionButton: some View {
        let isReadingBookAvailable = currentlyReadingBooks.first != nil
        
        return Button {
            if isReadingBookAvailable {
                navigationCoordinator.push(.dailyProgress)
            } else {
                navigationCoordinator.push(.bookSettingsManager)
            }
        } label: {
            Text(isReadingBookAvailable ? "오늘 독서 현황 기록하기" : "+ 완독할 책 추가하기")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(Color(red: 0.07, green: 0.87, blue: 0.54))
                }
        }
    }
}

#Preview {
    MainHomeView()
        .environment(NavigationCoordinator())
}
