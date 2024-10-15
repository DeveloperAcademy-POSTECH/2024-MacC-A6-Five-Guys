//
//  ProgressBar.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/14/24.
//

import SwiftUI

struct ProgressBar: View {
  
    @ObservedObject private var navigationRouter = NavigationRouter<ChatViewRoute>()
    
    var body: some View {
        HStack {
            // 프로그레스 바와 동그라미를 합치기 위한 z stack
            ZStack {
                // 프로그레스 바
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .frame(width: 305, height: 1)
                    .padding(.bottom, 18.5)
                HStack(alignment: .center) {
                    ProgressCircle(text: "사진")
                    Spacer()
                    ProgressCircle(text: "사진")
                    Spacer()
                    ProgressCircle(text: "사진")
                }
            }
        }
        .padding(.horizontal, 34)
    }
}
