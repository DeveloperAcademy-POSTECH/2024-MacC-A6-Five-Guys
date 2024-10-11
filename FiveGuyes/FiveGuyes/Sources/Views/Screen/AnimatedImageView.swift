//
//  AnimatedImageView.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/10/24.
//

import SwiftUI

struct AnimatedImageView: View {
    /// 애니메이션이 활성화되었는지 여부를 나타내는 상태 변수.
    @State private var isAnimating = false
    
    // TODO: 이후 앞에 로직에 따라 타입 변경 필요
    let imageName: String
    let animation: ImageAnimation
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .applyAnimation(animation, isAnimating: isAnimating)
            .onAppear {
                isAnimating = true  // 화면이 나타날 때 애니메이션을 시작
            }
    }
}

#Preview {
    AnimatedImageView(imageName: "imageDummy1", animation: .movedBy(-100))
}
