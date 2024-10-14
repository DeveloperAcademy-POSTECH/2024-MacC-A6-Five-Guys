//
//  ProgressBar.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/14/24.
//

import SwiftUI

struct ProgressBar: View {
  
    @ObservedObject private var navigationRouter = NavigationRouter<ChatViewRoute>()
    
    var body: some View {
        HStack {
            // 프로그레스 바와 동그라미를 합치기 위한 z stack
            ZStack {
                // 프로그레스 바
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .frame(height: 1)
                // 동그라미
                HStack(alignment: .center) {
                    VStack {
                        Circle()
                            .fill( Color(red: 0.85, green: 0.85, blue: 0.85))
                        
                            .onTapGesture {
                                navigationRouter.push(.photo)
                            }
                    }
                    Spacer()
                    VStack {
                        Circle().fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .frame(width: 20, height: 20)
                    }
                    .onTapGesture {
                        navigationRouter.push(.emotion)
                                               }
                    Spacer()
                    VStack {
                        Circle().fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .frame(width: 20, height: 20)
                        
                    }
                    .onTapGesture {
                        navigationRouter.push(.complete)
                                               }
                }
                Spacer()
                    .frame(height: 2.5)
                // 설명
                HStack {
                    Text("사진")
                        .font(
                            Font.custom("Pretendard", size: 14)
                                .weight(.medium)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                    Spacer()
                    Text("사진")
                        .font(
                            Font.custom("Pretendard", size: 14)
                                .weight(.medium)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                    Spacer()
                    Text("사진")
                        .font(
                            Font.custom("Pretendard", size: 14)
                                .weight(.medium)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                    
                }
                .padding(.horizontal, 31.5)
            }
            
        }
        .padding(.horizontal, 34)
    }
}

