//
//  MainView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/4/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Image(systemName: "bell")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            
            ScrollView {
                TitleView(title: "세니님, 반가워요\n완독하고 싶은 책이 있나요?")
                    .padding(.bottom, 24)
                
                ZStack {
                    Rectangle()
                        .foregroundColor(Color(red: 0.96, green: 0.98, blue: 0.97))
                        .frame(width: 353, height: 220)
                        .cornerRadius(16)
                        .padding(.bottom, 16)
                    VStack {
                        HStack {
                            Text("읽고 있는 책이 없어요!\n읽고 있는 책을 등록해주세요")
                                .lineSpacing(6)
                            Spacer()
                        }
                        .padding(24)
                        Spacer()
                        HStack {
                            Spacer()
                            Image("wandoki")
                                .resizable()
                                .frame(width: 134, height: 125)
                                .padding(.bottom, 12)
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    Button {
                        // TODO: 만약 책이 등록되면 활성화 - 전체 캘린더 뷰로 이동
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                            Text("전체")
                        }
                        .font(.system(size: 20))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .foregroundColor(Color.gray)
                        .background(Color(red: 0.98, green: 1, blue: 0.99))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .inset(by: 0.5)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    Button {
                        // TODO: 완독할 책 추가하기
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("완독할 책 추가하기")
                        }
                        .font(.system(size: 20))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 33)
                        .foregroundColor(Color.white)
                        .fontWeight(.semibold)
                        .background(Color.green)
                        .cornerRadius(16)
                    }
                }
                .padding(.bottom, 40)
                
                VStack(spacing: 24) {
                    TitleView(title: "완독 리스트")
                    
                    // 책 이미지 추가
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<1) { _ in
                                // 추후 Rectangle()을 Image()로 변경
                                Rectangle()
                                  .foregroundColor(.clear)
                                  .frame(width: 115, height: 178)
                                  .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                                  .cornerRadius(6)
                                  .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct TitleView: View {
    var title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22))
                .fontWeight(.semibold)
                .lineSpacing(6)
            Spacer()
        }
    }
}

#Preview {
    MainView()
}
