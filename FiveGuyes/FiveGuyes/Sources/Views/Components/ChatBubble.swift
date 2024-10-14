//
//  ChatBubbles.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/14/24.
//

import SwiftUI

struct ChatBotBubble: View {
    var message: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(message)
                .font(Font.custom("Pretendard", size: 20))
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .clipShape(ChatBotBubbleDesign(radius: 16, corners: [.topLeft, .topRight, .bottomRight]))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }
}

struct MyChatBubble: View {
    var message: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Body1/Regular
            Text(message)
                .font(Font.custom("Pretendard", size: 20))
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.94, green: 0.93, blue: 1))
        .clipShape(MyChatBubbleDesign(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 16)
    }
}
