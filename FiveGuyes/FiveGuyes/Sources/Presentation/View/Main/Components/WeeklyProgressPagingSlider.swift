//
//  WeeklyProgressPagingSlider.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/11/25.
//

import SwiftUI

struct WeeklyProgressPagingSlider: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    var readingBooks: [UserBook]
    
    let adjustedToday = Date().adjustedDate()
    
    private let spacing: CGFloat = 8
    
    @Binding var activeID: UUID?
    
    var body: some View {
        if !readingBooks.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: spacing) {
                    ForEach(readingBooks) { book in
                        WeeklyReadingProgressView(userBook: book, adjustedToday: adjustedToday)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $activeID)
        } else {
            VStack(spacing: 0) {
                EmptyImageDefaultView()
                    .offset(y: 10)
                    .zIndex(1)
                emptyProgressView
            }
        }
    }
    
    private var emptyProgressView: some View {
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
                .foregroundStyle(Color.Fills.white)
        }
        .commonShadow()
    }
}
