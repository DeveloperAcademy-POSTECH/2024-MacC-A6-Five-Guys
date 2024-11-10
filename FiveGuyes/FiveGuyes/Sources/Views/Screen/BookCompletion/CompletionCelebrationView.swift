//
//  CompletionCelebrationView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftData
import SwiftUI
// TODO:  완독 날짜 변경은 최종 저장할 때 수정하기

struct CompletionCelebrationView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @Query(filter: #Predicate<UserBook> { $0.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    private let celebrationTitleText = "완독 완료!"
    private let celebrationMessageText = "한 권을 전부 읽다니...\n대단한걸요?"
    
    // TODO: 컬러, 폰트 수정하기
    var body: some View {
        // TODO: 더미 지우기
        let userBook = currentlyReadingBooks.first ?? UserBook.dummyUserBook
        
        ZStack {
            // TODO: 확정된 배경 이미지로 변경하기
            Image("completionBackground").ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                celebrationTitle
                    .padding(.bottom, 14)
                
                celebrationMessage
                    .padding(.bottom, 80)
                
                celebrationBookImage(userBook)
                    .padding(.bottom, 28)
                
                readingSummary(userBook)
                
                Spacer()
                
                reflectionButton
                    .padding(.bottom, 42)
            }
            .padding(.horizontal, 16)
        }
        .customNavigationBackButton()
    }
    
    private var celebrationTitle: some View {
        Text(celebrationTitleText)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.green)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.white)
            }
    }
    
    private var celebrationMessage: some View {
        Text(celebrationMessageText)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
    }
    
    private func celebrationBookImage(_ userBook: UserBook) -> some View {
        let book = userBook.book
        // TODO: 캐릭터 이미지로 변경
        let overlayImage = Image("completedWandoki")
            .resizable()
            .scaledToFit()
            .frame(height: 89)
            .offset(y: -72)
        
        return Group {
            if let coverURL = book.coverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
            } else {
                // TODO: 이미지 없을 때 대용 이미지 추가하기
                Image("")
                    .resizable()
            }
        }
        .scaledToFill()
        .frame(width: 173, height: 267)
        .overlay(alignment: .top) {
            overlayImage
        }
    }
    
    private func readingSummary(_ userBook: UserBook) -> some View {
        let book = userBook.book
        let readingScheduleCalculator = ReadingScheduleCalculator()
        
        let startDateText = book.startDate.toKoreanDateString()
        // TODO: 완독을 수정할 수도 있기 때문에 완독 날짜가 바뀔 수 있음, 그래서 완독 날짜는 최종에서 업데이트하고 여기서는 오늘 날짜로 보여주기
        let endDateText = Date().toKoreanDateString()
        let pagesPerDay = readingScheduleCalculator.firstCalculatePagesPerDay(for: userBook)
        let totalReadingDays = readingScheduleCalculator.firstCalculateTotalReadingDays(for: userBook)
        
        return Text("\(startDateText)부터 \(endDateText)까지\n꾸준히 \(pagesPerDay)쪽씩 \(totalReadingDays)일동안 읽었어요 🎉")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.black)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.white)
            }
    }
    
    private var reflectionButton: some View {
        Button {
            navigationCoordinator.push(.completionReview)
        } label: {
            Text("완독 소감 작성하기")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(Color(red: 0.07, green: 0.87, blue: 0.54))
                }
        }
    }
}
