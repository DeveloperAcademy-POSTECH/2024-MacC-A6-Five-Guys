//
//  WeeklyReadingProgressView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct WeeklyReadingProgressView: View {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    // 텍스트 변경을 위한 추가 필요데이터
    let today = Date()
    
    var body: some View {
        // 텍스트 변경 기능을 위한 추가 코드
        // 현재 읽는 책을 가져옵니다
        if let currentReadingBook = currentlyReadingBooks.first {
            let todayRecords = currentReadingBook.getAdjustedReadingRecord(for: today)
            
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 8) {
                    if let todayRecords {
                        // 00~04시 여부 판단 ⏰
                        let isMidnightToFourAM = today.isInHourRange(start: 0, end: 4)
                        // 오늘 페이지를 읽어서 기록이 되면 타겟페이지와 같아지고 hasCompleteToday는 true 할당
                        let hasCompletedToday = todayRecords.pagesRead == todayRecords.targetPages
                        
                        // 텍스트 상수 정의
                        let primaryMessage = hasCompletedToday
                            ? "오늘도 성공이에요! 화이팅 🤩"
                            : isMidnightToFourAM
                                ? "아직 늦지 않았어요! 기록해볼까요?"
                                : "오늘은 \(todayRecords.targetPages)쪽 까지 읽어야해요!"
                        
                        let secondaryMessage = !hasCompletedToday && isMidnightToFourAM
                            ? "지금 기록해도 어제의 하루로 저장돼요!"
                            : "매일 방문하고 기록을 남겨보세요"
                        
                        Text(primaryMessage)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(secondaryMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.6))
                    }
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
                    Image("NothingWandoki")
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
