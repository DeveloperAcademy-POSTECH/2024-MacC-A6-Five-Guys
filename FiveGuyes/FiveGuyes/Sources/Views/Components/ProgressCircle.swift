//
//  ProgressCircle.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/14/24.
//

import SwiftUI

struct ProgressCircle: View {
    var text: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill( Color(red: 0.85, green: 0.85, blue: 0.85))
            Spacer()
                .frame(height: 2.5)
            HStack {
                Text(text)
                    .font(
                        Font.custom("Pretendard", size: 14)
                            .weight(.medium)
                    )
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            }
        }
    }
}
