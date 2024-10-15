//
//  FeedPagingRectangle.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/14/24.
//

import SwiftUI

struct FeedPagingRectangle: View {
    var progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.white.opacity(0.3))
                    .cornerRadius(5)
                
                Rectangle()
                    .frame(width: geometry.size.width * self.progress, alignment: .leading)
                    .foregroundColor(Color.white.opacity(0.9))
                    .cornerRadius(5)
                    .animation(.linear, value: progress)
            }
        }
    }
}
