//
//  CompletionCelebrationView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import SwiftUI

struct CompletionCelebrationView: View {
    // TODO: 책 관련 모델 만들기
    private let startDate = "2024년 11월 1일"
    private let endDate = "11월 30일"
    private let page = 9
    private let duration = 30
    private let bookImageName = "bookCoverDummy"
    
    private let celebrationTitleText = "완독 완료!"
    private let celebrationMessageText = "한 권을 전부 읽다니...\n대단한걸요?"
    
    // TODO: 컬러, 폰트 수정하기
    var body: some View {
        ZStack {
            // TODO: 확정된 배경 이미지로 변경하기
            Color.white.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 0) {
                celebrationTitle
                    .padding(.top, 37)
                    .padding(.bottom, 14)
                
                celebrationMessage
                    .padding(.bottom, 80)
                
                celebrationBookImage
                    .padding(.bottom, 24)
                
                readingSummary
                
                Spacer()
                
                reflectionButton
                    .padding(.bottom, 42)
            }
            .padding(.horizontal, 16)
        }
        .customNavigationBackButton()
        .ignoresSafeArea(edges: .bottom)
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
    
    private var celebrationBookImage: some View {
        Image(bookImageName)
            .resizable()
            .scaledToFit()
            .frame(width: 173)
            .overlay(alignment: .top) {
                // TODO: 캐릭터 이미지로 변경
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.red)
                    .frame(height: 80)
                    .offset(y: -75)
            }
    }
    
    private var readingSummary: some View {
        Text("\(startDate)부터 \(endDate)까지\n꾸준히 \(page)쪽씩 \(duration)일동안 읽었어요 🎉")
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
        NavigationLink {
            CompletionReviewView()
        } label: {
            Text("완독 소감 작성하기")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(.green)
                }
        }
    }
}

#Preview {
    NavigationStack {
        CompletionCelebrationView()
    }
}
