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
        VStack(alignment: .center) {
            Circle()
                .fill( Color(red: 0.85, green: 0.85, blue: 0.85))
                .frame(width: 20, height: 20)
            Spacer()
                .frame(height: 4)
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
