//
//  WeeklyReadingProgressView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftUI

struct WeeklyReadingProgressView: View {
    @Environment(UserLibrary.self) var uerLibrary: UserLibrary
    
    var body: some View {
        if let currentReadingBook = uerLibrary.currentReadingBook {
            
            VStack(alignment: .leading, spacing: 17) {
                
                VStack(alignment: .leading, spacing: 8) {
                    // TODO: n일 째 도전중 수정하기
                    Text("10일 째 도전중!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("매일 방문하고 기록을 남겨보세요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 22)
                .padding(.horizontal, 24)
                
                WeeklyPageCalendarView()
                    .padding(.horizontal, 15)
                    .padding(.bottom, 21)
                
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.white)
            }
            .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)

        } else {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .foregroundColor(Color(red: 0.96, green: 0.98, blue: 0.97))
                    .cornerRadius(16)
                    .frame(height: 178)
                
                Text("읽고 있는 책이 없어요!\n읽고 있는 책을 등록해주세요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.vertical, 22)
                    .padding(.horizontal, 24)
                
            }
            .overlay(alignment: .bottomTrailing) {
                // TODO: 이미지 변경 + 위치 조정
                Image("wandoki")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 102)
                    .padding(.trailing, 37)
            }
        }
    }
}

#Preview {
    WeeklyReadingProgressView()
}
