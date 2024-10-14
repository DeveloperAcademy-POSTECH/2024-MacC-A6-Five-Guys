//
//  ChatView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/13/24.
//

import SwiftUI

struct ChatView: View {
    
    @ObservedObject private var navigationRouter = NavigationRouter<ChatViewRoute>()
    
    var body: some View {
        NavigationStack(path: $navigationRouter.paths) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {                    // 여행기록하기 네비게이션 bar
                    Title()
                    Spacer()
                        .frame(height: 28)
                    ProgressBar()
                    Spacer()
                        .frame(height: 28)
                    // 말풍선 컴포넌트
                    HStack(alignment: .center, spacing: 10) {
                        // 텍스트필드
                        Text("반가워요. 유경님의 여행추억을\n대신 기억해주는 챗봇이에요!")
                            .font(Font.custom("Pretendard", size: 20))
                            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .clipShape(AiChatBubble(radius: 16, corners: [.topLeft, .topRight, .bottomRight]))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    
                    // 말풍선 사이 간격
                    Spacer()
                        .frame(height: 8)
                    
                    // 말풍선 컴포넌트
                    HStack(alignment: .center, spacing: 10) {
                        // Body1/Regular
                        Text("여행 기간을 알려주세요!")
                            .font(Font.custom("Pretendard", size: 20))
                            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .clipShape(AiChatBubble(radius: 16, corners: [.topLeft, .topRight, .bottomRight]))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    Spacer()
                        .frame(height: 8)
                    // 내 말풍선 컴포넌트
                    HStack(alignment: .center, spacing: 10) {
                        // Body1/Regular
                        Text("6박 7일, 이번주 토요일까지야")
                            .font(Font.custom("Pretendard", size: 20))
                            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.94, green: 0.93, blue: 1))
                    .clipShape(MyChatBubble(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                }
                .frame(width: 393, height: 54, alignment: .top)
                
            }
          //  .frame(width: 393, height: 852)
            .background(.white)
           
        }
        .navigationDestination(for: ChatViewRoute.self) { route in
            switch route {
            case .photo:
               PhotoChatView()
            case .emotion:
               EmotionChatView()
            case .complete:
                CompleteChatView()
            }
        }
        .environmentObject(navigationRouter)
    }
    
}

#Preview {
    ChatView()
}

