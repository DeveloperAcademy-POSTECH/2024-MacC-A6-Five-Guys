//
//  ChatView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/13/24.
//

import SwiftUI

struct DatePickerView: View {
    
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
                    // 말풍선 컴포넌트
                    ChatBotBubble(message: "반가워요. 유경님의 여행추억을\n대신 기억해주는 챗봇이에요!")
                    
                    // 말풍선 사이 간격
                    Spacer()
                        .frame(height: 8)
                    
                    // 말풍선 컴포넌트
                    ChatBotBubble(message: "여행 기간을 알려주세요!")
                    // dataPicker 자리
                    Spacer()
                    PurpleChatViewButton(text: "선택완료", action: {})
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
    DatePickerView()
}

