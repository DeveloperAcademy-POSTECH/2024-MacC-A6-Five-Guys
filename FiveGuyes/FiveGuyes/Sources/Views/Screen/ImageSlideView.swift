//
//  ImageSlideView.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/10/24.
//

import SwiftUI

struct ImageSlideView: View {
    @ObservedObject var progressTimer: FeedProgressTimer
    
    /// 모든 이미지에 적용할 애니메이션 (현재는 -100만큼 이동하는 애니메이션)
    private let animation = ImageAnimation.movedBy(-100)
    
    // TODO: 추후 더미 데이터 제외하고 앞선 로직에 따른 타입 변경 필요
    let feed: [String]
    
    var body: some View {
        TabView(selection: $progressTimer.feedImageIndex) {
            ForEach(0..<feed.count, id: \.self) { index in
                AnimatedImageView(imageName: feed[index], animation: animation)
            }
        }
        .containerRelativeFrame([.horizontal, .vertical])
        .background(.black)
    }
}
