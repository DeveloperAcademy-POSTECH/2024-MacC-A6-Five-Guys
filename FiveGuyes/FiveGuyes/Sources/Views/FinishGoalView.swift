//
//  FinishGoalView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/4/24.
//

import SwiftUI

struct FinishGoalView: View {
    var booktitle: String = "프리웨이"
    var bookauthor: String = "드로우앤드류"
    var completionstartdate: String = "11월 1일"
    var completionenddate: String = "11월 30일"
    var dailypage: Int = 9
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.98, blue: 0.97)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
        
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundColor(Color.green)
                    .padding(.bottom, 18)
                
                Text("완독 목표 설정 완료")
                    .foregroundColor(Color.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.bottom, 40)
                
                HStack(spacing: 0) {
                    TextView(text: "매일 ")
                    
                    Text("\(dailypage)")
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(Color.green)
                        .background(Color.white)
                        .cornerRadius(8)
                    TextView(text: " 쪽만 읽으면")
                }
                .padding(.bottom, 3)
                
                TextView(text: "완독할 수 있어요!")
                    .padding(.bottom, 48)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 304, height: 172)
                        .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                    
                    HStack(spacing: 0) {
                        Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 90, height: 139)
                        .background(
                        Image("bookimage") // 받아올 책 이미지
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 139)
                        .clipped()
                        )
                        .padding(.leading, 20)
                        
                        VStack(alignment: .leading) {
                            // 책 제목
                            Text(booktitle)
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                .padding(.top, 17)
                            
                            // 저자
                            Text(bookauthor)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                            
                            // 완독 목표 기간
                            Text("\(completionstartdate) ~ \(completionenddate)")
                                .foregroundColor(Color.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.93, green: 0.97, blue: 0.95))
                                .cornerRadius(8)
                            
                            // 하루 권장 독서량
                            Text("하루 권장 독서량 : \(dailypage)쪽")
                                .foregroundColor(Color.green)
                                .font(.system(size: 16))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.93, green: 0.97, blue: 0.95))
                                .cornerRadius(8)
                                .padding(.bottom, 16)
                            
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 45)
                }
                .padding(.bottom, 115)
                
                Button {
                    // TODO: MainView로 이동
                } label: {
                    HStack {
                        Text("확인")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.green)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }

            }
        }
    }
}

struct TextView: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 24))
            .fontWeight(.semibold)
    }
}
                        
#Preview {
    FinishGoalView()
}
