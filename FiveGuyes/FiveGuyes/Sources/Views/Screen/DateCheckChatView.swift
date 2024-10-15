//
//  ChatView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/13/24.
//

import SwiftUI

struct DateCheckChatView: View {
    
    @ObservedObject private var navigationRouter = NavigationRouter<ChatViewRoute>()
    
    var body: some View {
        NavigationStack(path: $navigationRouter.paths) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // 여행기록하기 네비게이션 bar
                    Title()
                    Spacer()
                        .frame(height: 28)
                    
                    ProgressBar()
                    Spacer()
                        .frame(height: 28)
                  
                    MyChatBubble(message: "6박 7일, 이번주 토요일까지야")
                        .frame(width: 393, height: 54, alignment: .top)
                    // 말풍선 사이 간격
                    Spacer()
                        .frame(height: 8)
                    // 말풍선 컴포넌트
                    ChatBotBubble(message: "그렇군요!")
                    // 말풍선 사이 간격
                    Spacer()
                        .frame(height: 8)
                    
                    // 말풍선 컴포넌트
                    ChatBotBubble(message: "혹시, 지금 시드니인가요?")
                   
                    
                    // 버튼
                    Spacer()
                   
                    PurpleChatViewButton(text: "맞아", action: {})
                    // 버튼 사이 간격
                    Spacer()
                        .frame(height: 8)
                    WhiteChatViewButton(text: "아니야", action: {})
                        .padding(.bottom, 45)
                }
                
            }
            .background(.white)
            
        }
        .navigationDestination(for: ChatViewRoute.self) { route in
            switch route {
            case .photo:
                Text("사진으로 넘어감")
            case .emotion:
                Text("감정으로 넘어감")
            case .complete:
                Text("완료로 넘어감")
            }
        }
        .environmentObject(navigationRouter)
    }
    
}

#Preview {
    DateCheckChatView()
}

