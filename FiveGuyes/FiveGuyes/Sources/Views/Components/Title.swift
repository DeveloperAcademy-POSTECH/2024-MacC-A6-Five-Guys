//
//  Title.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/14/24.
//

import SwiftUI

struct Title: View {
    var title: String = "여행 기록하기"
    
    var body: some View {
        HStack {
            Button(action: {
             // 버튼 액션
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            }
            Text(title)
                .font(
                    Font.custom("Pretendard", size: 24)
                        .weight(.semibold)
                )
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
