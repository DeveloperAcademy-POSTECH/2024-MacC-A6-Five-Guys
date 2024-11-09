//
//  MainHomeView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftUI

struct MainHomeView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(UserLibrary.self) var uerLibrary: UserLibrary
    
    @State private var topSafeAreaInset: CGFloat = 0
    
    var body: some View {
        
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
                    .padding(.bottom, 37)
                    
                    titleDescription
                        .padding(.bottom, 40)
                    
                    ZStack(alignment: .top) {
                        
                        WeeklyReadingProgressView()
                            .padding(.top, 153)
                        
                        if let currentReadingBook = uerLibrary.currentReadingBook,
                           let coverURL = currentReadingBook.book.coverURL,
                           let url = URL(string: coverURL) {
                            // TODO: 옆에 책 제목, 저자 text 추가하기
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 104, height: 161)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            // TODO: 등록된 책이 없을 때 이미지로 대체
                            Rectangle()
                                .foregroundColor(.gray)
                                .frame(width: 104, height: 161)
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
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
        .onAppear {
            // 상단 안전 영역 값 계산
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first {
                topSafeAreaInset = window.safeAreaInsets.top
            }
        }
    }
    
    private var titleDescription: some View {
        HStack {
            if let currentReadingBook = uerLibrary.currentReadingBook {
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("<\(currentReadingBook.book.title)>")
                        .lineLimit(1)
                    // TODO: 완독까지 날짜 계산하기
                    Text("완독까지 20일 남았어요!")
                }
                
            } else {
                VStack(alignment: .leading, spacing: 0) {
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
        let isReadingBookAvailable = uerLibrary.currentReadingBook != nil
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
        let isReadingBookAvailable = uerLibrary.currentReadingBook != nil
        
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
                        .foregroundColor(.green)
                }
        }
    }
}

#Preview {
    MainHomeView()
        .environment(NavigationCoordinator())
}
