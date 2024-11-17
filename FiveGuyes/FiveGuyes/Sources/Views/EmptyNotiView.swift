//
//  EmptyNotiView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/4/24.
//

import SwiftUI

// TODO: 완독이 이미지 바꾸기
struct EmptyNotiView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("NothingWandoki")
                .resizable()
                .scaledToFit()
                .frame(width: 194)
                .padding(.bottom, 10)
            Text("아직 도착한 알림이 없어요")
                .font(.system(size: 24, weight: .semibold))
        }
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .customNavigationBackButton()
    }
}

#Preview {
    EmptyNotiView()
}
