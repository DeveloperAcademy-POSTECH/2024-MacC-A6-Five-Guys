//
//  ChatViewButton.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/14/24.
//

import SwiftUI

struct PurpleChatViewButton: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Title1/SemiBold
            Text(text)
              .font(
                Font.custom("Pretendard", size: 24)
                  .weight(.semibold)
              )
              .multilineTextAlignment(.center)
              .foregroundColor(.white)
        }
        .padding(.horizontal, 130)
        .padding(.vertical, 12)
        .frame(width: 361, height: 60, alignment: .center)
        .background(Color(red: 0.5, green: 0.37, blue: 1))
        .cornerRadius(16)
    }
}

struct WhiteChatViewButton: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Title1/SemiBold
            Text(text)
              .font(
                Font.custom("Pretendard", size: 24)
                  .weight(.semibold)
              )
              .multilineTextAlignment(.center)
              .foregroundColor(Color(red: 0.5, green: 0.37, blue: 1))
        }
        .padding(.horizontal, 130)
        .padding(.vertical, 12)
        .frame(width: 361, height: 60, alignment: .center)
        .background(Color(red: 0.94, green: 0.93, blue: 1))
        .cornerRadius(16)
    }
}
