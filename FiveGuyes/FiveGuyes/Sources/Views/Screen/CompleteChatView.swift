
//  CompleteChatView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/13/24.
//

import SwiftUI

struct CompleteChatView: View {

    @ObservedObject private var navigationRouter = NavigationRouter<ChatViewRoute>()

    var body: some View {
        NavigationStack(path: $navigationRouter.paths) {
            ZStack(alignment: .top) {
                // status bar
                VStack(spacing: 0) {
                    HStack(spacing: 112) {
                        HStack(alignment: .center, spacing: 0) { Text("9:41")
                                .font(
                                    Font.custom("SF Pro", size: 17)
                                        .weight(.semibold)
                                )
                                .multilineTextAlignment(.center)
                            .foregroundColor(.black) }
                        .padding(.horizontal, 0)
                        .padding(.top, 18.33962)
                        .padding(.bottom, 13.66038)
                        .frame(maxWidth: .infinity, alignment: .center)

                        Image("Levels")
                            .frame(maxWidth: .infinity, minHeight: 54, maxHeight: 54)
                    }

                    // 여행기록하기 네비게이션 bar
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                        Text("여행 기록하기")
                            .font(
                                Font.custom("Pretendard", size: 24)
                                    .weight(.semibold)
                            )
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                            .frame(maxWidth: .infinity)
                        Spacer()

                    }
                    .padding(.horizontal, 32)
                    Spacer()
                        .frame(height: 28)
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
                                        .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                                        .frame(width: 20, height: 20)
                                        .onTapGesture {
                                            navigationRouter.push(.photo)
                                                                   }
                                    /*
                                     Image("Ellipse 17")
                                     .frame(width: 20, height: 20)
                                     )
                                     */
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
                        }
                    }
                    .padding(.horizontal, 34)
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
                    Spacer()
                        .frame(height: 28)
                    HStack(alignment: .center, spacing: 10) {
                        // Body1/Regular
                        Text("시드니 하버브릿지 앞 공원에서  따뜻한 햇살을 받으며 산책했을 때~\n평소에 느끼지 못했던 여유를 느꼈지.")
                          .font(Font.custom("Pretendard", size: 20))
                          .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                          .frame(width: 319.54688, height: 92.61719, alignment: .topLeading)

                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.94, green: 0.93, blue: 1))
                    .clipShape(MyChatBubble(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                    Spacer()
                        .frame(height: 8)
                    // 말풍선 컴포넌트
                    HStack(alignment: .center, spacing: 10) {
                        // 텍스트필드
                        Text("유경님이 적어주신 내용을\n사진과 함께 기록해드릴게요.")
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
                        Text("기록이 완료되었어요!")
                          .font(Font.custom("Pretendard", size: 20))
                          .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .clipShape(AiChatBubble(radius: 16, corners: [.topLeft, .topRight, .bottomRight]))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                }
                .frame(width: 393, height: 54, alignment: .top)
            }
            .frame(width: 393, height: 852)
            .background(.white)
        }
        .navigationDestination(for: ChatViewRoute.self) { route in
            switch route {
            case .photo:
                Text("Photo View") // Replace with actual view
            case .emotion:
                Text("Emotion View") // Replace with actual view
            case .complete:
                Text("Complete View") // Replace with actual view
            }
        }
    }
}

#Preview {
    CompleteChatView()
}

