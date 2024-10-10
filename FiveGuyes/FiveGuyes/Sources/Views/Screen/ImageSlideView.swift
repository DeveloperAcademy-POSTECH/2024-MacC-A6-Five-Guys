//
//  ImageSlideView.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/10/24.
//

import SwiftUI

struct ImageSlideView: View {
    @State private var selectedIndex = 0
    
    /// 모든 이미지에 적용할 애니메이션 (현재는 -100만큼 이동하는 애니메이션)
    private let animation = ImageAnimation.movedBy(-100)
    /// 2초마다 이미지를 변경하는 타이머.
    private let timer = Timer.publish(every: 2, on: .current, in: .common).autoconnect()
    // TODO: 추후 더미 데이터 제외하고 앞선 로직에 따른 타입 변경 필요
    private let imageNames = ["imageDummy1", "imageDummy2", "imageDummy3", "imageDummy4", "imageDummy5"]
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(imageNames.indices, id: \.self) {
                AnimatedImageView(imageName: imageNames[$0], animation: animation)
            }
        }
        .tabViewStyle(.automatic)
        .onReceive(timer, perform: { _ in
            let nextIndex = (selectedIndex + 1) % imageNames.count
            selectedIndex = nextIndex
        })
        .background(.black)
    }
}

#Preview {
    ImageSlideView()
}
