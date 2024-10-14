//
//  FeedView.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/14/24.
//

import SwiftUI

struct FeedView: View {
    //TODO: 현재 손으로 스크롤 할 때는 해당 인덱스에 반영이 안된다.
    @State private var currentFeedIndex = 0 // 현재 인덱스를 저장
    
    @StateObject var progressTimer = FeedProgressTimer(feedImageCount: 5, interval: 2.0)
    
    //TODO: 모델을 추가한 뒤에 수정해주기
    let dummyFeeds = [["imageDummy1", "imageDummy2", "imageDummy3", "imageDummy4", "imageDummy5"],
                 ["imageDummy2", "imageDummy3", "imageDummy4", "imageDummy5"],
                 ["imageDummy3", "imageDummy4", "imageDummy5"],
                 ["imageDummy2", "imageDummy4", "imageDummy5", "imageDummy1"],
                 ["imageDummy1", "imageDummy2", "imageDummy3", "imageDummy4", "imageDummy5"]]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(0..<dummyFeeds.count, id: \.self) { index in
                        ImageSlideView(progressTimer: progressTimer, feed: dummyFeeds[index])
                            .onAppear {
                                // Feed가 바뀜에 따라 Timer Update
                                progressTimer.feedImageCount = dummyFeeds[index].count
                                progressTimer.start()
                                progressTimer.onFeedFinished = self.moveToNextPage
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            .onChange(of: currentFeedIndex) {
                withAnimation {
                    proxy.scrollTo(currentFeedIndex, anchor: .top)
                }
            }
        }
        .overlay(alignment: .top) {
            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<dummyFeeds[currentFeedIndex].count, id: \.self) { idx in
                    FeedPagingRectangle(progress: min(max((CGFloat(self.progressTimer.progress) - CGFloat(idx)), 0.0), 1.0))
                        .frame(height: 3, alignment: .leading)
                }
            }
            .padding()
        }
        .onAppear {
            progressTimer.start()
        }
        .onDisappear {
            progressTimer.cancel()
        }
    }
    
    // 다음 페이지로 이동하는 함수
    private func moveToNextPage() {
        if currentFeedIndex < (dummyFeeds.count - 1) { // 마지막 페이지가 아니라면
            currentFeedIndex += 1
        } else {
            currentFeedIndex = 0 // 마지막 페이지이면 처음으로 돌아감
            //TODO: 피드 나가기
        }
    }
}

#Preview {
    FeedView()
}
