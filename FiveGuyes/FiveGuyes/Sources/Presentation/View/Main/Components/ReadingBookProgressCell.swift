//
//  ReadingBookProgressCell.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/13/25.
//

import SwiftUI

// 읽고 있는 책의 정보를 보여주는 셀(책 한 권에 관해서)
struct ReadingBookProgressCell: View {
    let book: FGUserBook
    let today: Date
    
    private var readingState: FGReadingProgress.TodayReadingState {
        book.readingProgress.readingState(on: today)
    }
    
    private var remainingDays: Int {
        book.userSettings.remainingReadingDays(today: today)
    }
    
    // MARK: - Layout
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundCard()
            
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        remainingDaysBadge(remainingDays)
                        readingStatePrompt(readingState)
                    }
                    
                    Spacer()
                    
                    userBookImage(book)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                WeeklyProgressCalendar(
                    userBook: book,
                    today: today
                )
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func backgroundCard() -> some View {
        Rectangle()
            .frame(height: 202)
            .foregroundStyle(Color.Backgrounds.primary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 4)
    }
    
    private func remainingDaysBadge(_ days: Int) -> some View {
        Text("완독까지 D-\(days)")
            .fontStyle(.caption1, weight: .regular)
            .foregroundStyle(Color.Colors.green2)
            .padding(.horizontal, 4)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .inset(by: 0.5)
                    .stroke(Color.Separators.green, lineWidth: 1)
            }
    }
    
    @ViewBuilder
    private func userBookImage(_ userBook: FGUserBook) -> some View {
        if let coverURL = userBook.bookMetaData.coverImageURL,
           let url = URL(string: coverURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
            } placeholder: {
                ProgressView()
            }
            .scaledToFit()
            .frame(width: 104, height: 161)
            .clipToBookShape()
        } else {
            emptyUserBookImage()
        }
    }
    
    private func emptyUserBookImage() -> some View {
        Rectangle()
            .foregroundStyle(Color.Fills.white)
            .frame(width: 104, height: 161)
            .clipToBookShape()
            .commonShadow()
    }
    
    private func promptTexts(for state: FGReadingProgress.TodayReadingState) -> (primary: String, secondary: String) {
        switch state {
        case .completed:
            return ("오늘도 성공이에요! 잘했어요 👏",
                    "매일 조금씩, 완독에 가까워지고 있어요")
        case .gracePeriodUnfinished:
            return ("아직 늦지 않았어요!",
                    "지금 기록해도 어제의 하루로 인정돼요")
        case let .unfinished(targetPages):
            return ("오늘은 \(targetPages)쪽까지 읽어보세요!",
                    "매일 방문하여 독서 현황을 기록해요!")
        case .rest:
            return ("오늘은 쉬는 날이에요 💤",
                    "잠시 쉬어가도 좋아요")
        }
    }
    
    private func readingStatePrompt(_ state: FGReadingProgress.TodayReadingState) -> some View {
        let prompt = promptTexts(for: state)
        
        return VStack(alignment: .leading, spacing: 0) {
            Text(prompt.primary)
                .fontStyle(.body, weight: .semibold)
                .foregroundStyle(Color.Labels.primaryBlack1)
            
            Text(prompt.secondary)
                .fontStyle(.caption1)
                .foregroundStyle(Color.Labels.secondaryBlack2)
        }
    }
}

#Preview {
    ReadingBookProgressCell(book: .dummy, today: Date())
        .background(.blue) // 프리뷰에서 흰색 카드가 보이도록 파란 배경 추가
}
