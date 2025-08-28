//
//  TotalCalendarView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/6/24.
//

import SwiftUI

struct ReadingStatusView: View {
    
    // MARK: - Properties
    
    @State private var currentIndex: Int? = 0
    
    @State private var currentMonths: [Date]
    private let todayDate = Date().adjustedDate()
    
    let currentReadingBooks: [FGUserBook]
    
    // MARK: - Initializer
    
    init(currentReadingBooks: [FGUserBook]) {
        self.currentReadingBooks = currentReadingBooks
        _currentMonths = State(initialValue: Array(repeating: todayDate, count: currentReadingBooks.count))
    }
    
    // MARK: - Layout
    
    var body: some View {
        VStack(spacing: 0) {
            bookInfoHeader(for: currentReadingBooks[currentIndex ?? 0])
                .padding(.top, 10)
                .padding(.bottom, 8)
                .padding(.horizontal, 20)
            
            indicatorView()
                .padding(.bottom, 22)
                .padding(.horizontal, 20)
            
            totalCalendarScrollView()
                .contentMargins(.horizontal, 24, for: .scrollContent)
                .padding(.bottom, 12)
            
            CompletionFooter(for: currentReadingBooks[currentIndex ?? 0])
                .padding(.leading, 32)
                .padding(.trailing, 24)
            
            Spacer()
        }
        .navigationTitle("전체 독서 현황")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
        .onAppear {
            // GA4 Tracking
            Tracking.Screen.calendarView.setTracking()
        }
    }
    
    // MARK: - Subviews
    
    private func bookInfoHeader(for book: FGUserBook) -> some View {
        HStack(alignment: .top) {
            Text(book.bookMetaData.title)
                .fontStyle(.title1, weight: .semibold)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .foregroundStyle(Color.Labels.primaryBlack1)
                .frame(height: 72, alignment: .top)
            
            Spacer()
            
            if let coverImageURLString = book.bookMetaData.coverImageURL,
               let url = URL(string: coverImageURLString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 68)
                        .clipShape(
                            UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 8, topTrailing: 8))
                        )
                } placeholder: {
                    ProgressView()
                }
            }
        }
    }
    
    private func indicatorView() -> some View {
        HStack(spacing: 2) {
            ForEach(currentReadingBooks.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.Labels.primaryBlack1 : Color.Labels.quaternaryBlack4)
                    .frame(width: 4, height: 4)
            }
            
            Spacer()
        }
    }
    
    private func totalCalendarScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(currentReadingBooks.indices, id: \.self) { index in
                    TotalCalendarView(currentReadingBook: currentReadingBooks[index])
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentIndex)
    }
        
    private func CompletionFooter(for currentReadingBook: FGUserBook) -> some View {
        HStack(alignment: .center) {
            Text("완독 종료일")
                .fontStyle(.body, weight: .semibold)
            
            Spacer()
            
            Text(currentReadingBook.userSettings.targetEndDate.formattedCompletionDateString())
                .fontStyle(.body, weight: .regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Colors.green2)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Color.Fills.lightGreen)
                .cornerRadius(8)
        }
    }
}
