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
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    
    @Query(filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == false })
    private var currentlyReadingBooks: [UserBook]  // 현재 읽고 있는 책을 가져오는 쿼리
    
    private let celebrationTitleText = "완독 완료!"
    private let celebrationMessageText = "한 권을 전부 읽다니...\n대단한걸요?"
    
    // TODO: 컬러, 폰트 수정하기
    var body: some View {
        let userBook = currentlyReadingBooks.first ?? UserBook.dummyUserBookV2
        
        let bookMetadata: BookMetaDataProtocol = userBook.bookMetaData
        let userSettings: UserSettingsProtocol = userBook.userSettings
        let readingProgress: any ReadingProgressProtocol = userBook.readingProgress
        
        ZStack {
            Image("completionBackground").ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                celebrationTitle
                    .padding(.bottom, 14)
                
                celebrationMessage
                    .padding(.bottom, 80)
                
                celebrationBookImage(bookMetadata)
                    .padding(.bottom, 28)
                
                readingSummary(userSettings: userSettings, readingProgress: readingProgress)
                
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
            .fontStyle(.body, weight: .semibold)
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
            .fontStyle(.title1, weight: .semibold)
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
    }
    
    private func celebrationBookImage(_ bookMetadata: BookMetaDataProtocol) -> some View {
        let overlayImage = Image("CompletedWandoki")
            .resizable()
            .scaledToFit()
            .frame(height: 89)
            .offset(y: -72)
        
        return Group {
            if let coverURL = bookMetadata.coverURL, let url = URL(string: coverURL) {
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
    
    private func readingSummary(userSettings: UserSettingsProtocol, readingProgress: any ReadingProgressProtocol) -> some View {
        let readingScheduleCalculator = ReadingScheduleCalculator()
         
        // TODO: 완독을 수정할 수도 있기 때문에 완독 날짜가 바뀔 수 있음, 그래서 완독 날짜는 최종에서 업데이트하고 여기서는 오늘 날짜로 보여주기 -> 초기 설정 날보다 빠를 수도 있음 🐯
        let endDateText = Date().toKoreanDateString()
        var startDateText = userSettings.startDate.toKoreanDateString()
        if startDateText > endDateText { startDateText = endDateText }
        
        // TODO: 위에 이유로 날짜가 바껴서 보이면 아래 로직에 파라미터 값도 바껴야 한다. 🐯
        let pagesPerDay = readingScheduleCalculator.firstCalculatePagesPerDay(settings: userSettings, progress: readingProgress).pagesPerDay
        
        let totalReadingDays = readingScheduleCalculator.firstCalculateTotalReadingDays(settings: userSettings, progress: readingProgress)
        
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
                .fontStyle(.title2, weight: .semibold)
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
