//
//  WeeklyReadingProgressView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftUI

struct WeeklyReadingProgressView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    var userBook: UserBook
    
    let adjustedToday: Date
    
    var body: some View {
        let todayRecords = userBook.readingProgress.getAdjustedReadingRecord(for: adjustedToday)
        VStack(spacing: -3) {
            AnyView(userBookImage(userBook))
            
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 0) {
                    if let todayRecords {
                        // 00~04시 여부 판단 ⏰
                        let isMidnightToFourAM = adjustedToday.isInHourRange(start: 0, end: 4)
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
                .padding(.horizontal, 16)
                
                WeeklyProgressCalendar(userBook: userBook)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color.Fills.white)
                    .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
            }
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
    
    private func userBookImage(_ userBook: UserBook) -> any View {
        if let coverURL = userBook.bookMetaData.coverURL,
           let url = URL(string: coverURL) {
            return AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 104, height: 161)
                    .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
            } placeholder: {
                ProgressView()
            }
        } else {
            return Rectangle()
                .foregroundStyle(Color.Fills.white)
                .frame(width: 104, height: 161)
                .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
        }
    }
    
}
