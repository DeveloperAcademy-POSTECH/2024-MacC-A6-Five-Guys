
//  ChatBubble.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/13/24.
//
import SwiftUI

// Custom shape with lower right corner not rounded
struct AiChatBubble: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = [.topLeft, .topRight, .bottomRight]

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MyChatBubble: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft]

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
