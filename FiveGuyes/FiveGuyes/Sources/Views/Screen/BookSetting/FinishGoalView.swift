//
//  FinishGoalView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/4/24.
//

import SwiftUI

struct FinishGoalView: View {
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var pagesPerDay: Int = 0
    @State var userBook: UserBook?
    
    private let calculator = ReadingScheduleCalculator()
    private let notificationManager = NotificationManager()
    
    var body: some View {
        
        if let book = bookSettingInputModel.selectedBook,
           let totalPages = Int(bookSettingInputModel.totalPages),
           let startDate = bookSettingInputModel.startData,
           let endDate = bookSettingInputModel.endData {
            
            ZStack {
                Color(red: 0.96, green: 0.98, blue: 0.97)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 56, height: 56)
                        .foregroundColor(Color.green)
                        .padding(.bottom, 14)
                    
                    Text("완독 목표 설정 완료")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                    
                    HStack(spacing: 0) {
                        TextView(text: "매일 ")
                        
                        Text("\(pagesPerDay)")
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                            .background(Color.white)
                            .cornerRadius(8)
                        
                        TextView(text: " 쪽만 읽으면")
                    }
                    .padding(.bottom, 3)
                    
                    TextView(text: "완독할 수 있어요!")
                        .padding(.bottom, 48)
                    
                    /// book card view
                    HStack(spacing: 16) {
                        if let coverUrl = book.cover, let url = URL(string: coverUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 139)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            // 이미지 없을 때
                            Rectangle()
                                .foregroundColor(.green)
                                .frame(width: 90, height: 139)
                                .padding(.leading, 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 0) {
                                // 책 제목
                                
                                Text(book.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.top, 17)
                                    .lineLimit(1)
                                
                                // 저자
                                Text(book.author.removingParenthesesContent())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                                    .lineLimit(1)
                            }
                            
                            // 완독 목표 기간
                            Text("\(formatDateToKorean(startDate)) ~ \(formatDateToKorean(endDate))")
                                .foregroundColor(Color.black)
                                .font(.system(size: 16))
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.93, green: 0.97, blue: 0.95))
                                .cornerRadius(8)
                            
                            // 하루 권장 독서량
                            Text("하루 권장 독서량 : \(pagesPerDay)쪽")
                                .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                                .font(.system(size: 16, weight: .medium))
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.93, green: 0.97, blue: 0.95))
                                .cornerRadius(8)
                                .padding(.bottom, 16)
                            
                        }
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                    }
                    .padding(.horizontal, 44)
                    
                    Spacer()
                    
                    Button {
                        // 책 정보 저장하기
                        if let userBook = userBook {
                            modelContext.insert(userBook) // SwiftData에 새로운 책 저장
                            
                            // 노티 세팅하기
                            setNotification(userBook)
                            navigationCoordinator.popToRoot()
                        } else {
                            print("책 정보 없음")
                        }
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
            .onAppear {
                // 1일 할당량 계산
                // TODO: 해당 모델 객체를 더 잘 만들 방식 고민하기
                let bookData = UserBook(book: BookDetails(title: book.title, author: book.author, coverURL: book.cover, totalPages: totalPages, startDate: startDate, targetEndDate: endDate, nonReadingDays: bookSettingInputModel.nonReadingDays))
                calculator.calculateInitialDailyTargets(for: bookData)
                userBook = bookData
                pagesPerDay = calculator.firstCalculatePagesPerDay(for: bookData).pagesPerDay
            }
        }
        
    }
    
    private func formatDateToKorean(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        //        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일"
        return dateFormatter.string(from: date)
    }
    
    private func setNotification(_ readingBook: UserBook) {
        notificationManager.clearRequests()
        Task {
            await self.notificationManager.setupNotifications(notificationType: .morning(readingBook: readingBook))
            
            await self.notificationManager.setupNotifications(notificationType: .night(readingBook: readingBook))
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
