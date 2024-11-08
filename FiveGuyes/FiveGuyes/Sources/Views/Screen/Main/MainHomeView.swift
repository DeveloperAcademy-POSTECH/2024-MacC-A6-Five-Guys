//
//  MainHomeView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftUI

struct MainHomeView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
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
                    
                    HStack {
                        Text("환영해요!\n저와 함께 완독을 시작해볼까요?")
                        Spacer()
                    }
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.bottom, 193)
                    
                    WeeklyReadingProgressView()
                        .padding(.bottom, 16)
                    
                    HStack(spacing: 16) {
                        calendarFullScreenButton {
                            // TODO: 페이지 이동
                        }
                        .frame(width: 107)
                        
                        addBookButton {
                            navigationCoordinator.push(.bookSettingsManager)
                        }
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
    
    private func notiButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "bell")
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 19)
                .tint(.black)
        }
    }
    
    private func calendarFullScreenButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                Text("전체")
            }
            .font(.system(size: 20, weight: .medium))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(.gray)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color(red: 0.98, green: 1, blue: 0.99))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.5)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
        }
    }
    private func addBookButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("+ 완독할 책 추가하기")
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
