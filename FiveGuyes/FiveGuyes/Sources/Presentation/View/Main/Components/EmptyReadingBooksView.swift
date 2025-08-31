//
//  EmptyReadingBooksView.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/30/25.
//

import SwiftUI

enum EmptyReadingState {
    case noCompleted      // 완독도 없고 읽는 책도 없음
    case hasCompleted     // 완독은 있는데 읽는 책은 없음
}

struct EmptyReadingBooksView: View {
    let state: EmptyReadingState
    
    private var title: String {
        switch state {
        case .noCompleted:
            return "책이 아직 등록되지 않았어요!"
        case .hasCompleted:
            return "독서 기록이 쌓이고 있어요!"
        }
    }
    
    private var subtitle: String {
        switch state {
        case .noCompleted:
            return "현재 읽고 있는 책을 등록해주세요"
        case .hasCompleted:
            return "새로운 한 권을 추가해보세요"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .foregroundStyle(Color.Labels.secondaryBlack2)
                    .fontStyle(.body, weight: .semibold)
                Text(subtitle)
                    .foregroundStyle(Color.Labels.secondaryBlack2)
                    .fontStyle(.caption1)
            }
            .padding(.bottom, 24)
            
            HStack {
                Spacer()
                Image("NothingWandoki")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 162)
            }
        }
        .padding(16)
        .background {
            backgroundCard()
        }
    }
    
    private func backgroundCard() -> some View {
        Rectangle()
            .foregroundStyle(Color.Backgrounds.primary)
            .cornerRadius(16)
    }
}

#Preview {
    VStack(spacing: 50) {
        EmptyReadingBooksView(state: .noCompleted)
        EmptyReadingBooksView(state: .hasCompleted)
    }
    .background(.blue)
    
}
