//
//  WeeklyReadingProgressView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct WeeklyReadingProgressView: View {
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    var body: some View {
        if let currentReadingBook = currentlyReadingBooks.first {
            VStack(alignment: .leading, spacing: 17) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(currentReadingBook.nonZeroReadingDaysCount())일 째 도전중!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("매일 방문하고 기록을 남겨보세요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 22)
                .padding(.horizontal, 24)
                
                WeeklyPageCalendarView(currentReadingBook: currentReadingBook)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 21)
                
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
            }
            
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text("읽고 있는 책이 없어요!\n읽고 있는 책을 등록해주세요")
                        .lineSpacing(6)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Image("nothingWandoki")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 162)
                        .padding(.bottom, 8)
                }
            }
            .padding(.top, 22)
            .padding(.horizontal, 24)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color(red: 0.96, green: 0.98, blue: 0.97))
            }
            .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
        }
    }
}

#Preview {
    WeeklyReadingProgressView()
}
