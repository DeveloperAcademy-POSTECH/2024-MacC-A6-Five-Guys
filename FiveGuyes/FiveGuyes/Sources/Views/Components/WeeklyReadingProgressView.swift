//
//  WeeklyReadingProgressView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct WeeklyReadingProgressView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @Query(filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    // 텍스트 변경을 위한 추가 필요데이터
    let today = Date()
    
    var body: some View {
        // 텍스트 변경 기능을 위한 추가 코드
        // 현재 읽는 책을 가져옵니다
        if let currentReadingBook = currentlyReadingBooks.first {
            let todayRecords = currentReadingBook.readingProgress.getAdjustedReadingRecord(for: today)
            
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 0) {
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
                        
                        primaryMessageText(primaryMessage)
                        secondaryMessageText(secondaryMessage)
                        
                    } else {
                        primaryMessageText("오늘은 쉬는 날이에요! 잠시 쉬어가요 📖💤")
                        secondaryMessageText("하루 쉬어가도 괜찮아요. 꾸준함이 중요하니까요!")
                    }
                }
                .padding(.top, 22)
                .padding(.horizontal, 24)
                
                WeeklyPageCalendarView()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 18)
                
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.white)
                    .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
            }
            
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text("읽고 있는 책이 없어요!\n읽고 있는 책을 등록해주세요")
                        .lineSpacing(6)
                        .fontStyle(.body)
                        .foregroundStyle(Color.Labels.secondaryBlack2)
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
                    .foregroundStyle(Color.Fills.white) // 피그마대로 white 로 변경
            }
            .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
        }
    }
    
    private func primaryMessageText(_ message: String) -> some View {
        Text(message)
            .fontStyle(.body, weight: .semibold)
            .foregroundStyle(Color.Labels.primaryBlack1)
    }
    
    private func secondaryMessageText(_ message: String) -> some View {
        Text(message)
            .fontStyle(.caption1)
            .foregroundStyle(Color.Labels.secondaryBlack2)
    }
    
}

#Preview {
    WeeklyReadingProgressView()
}
