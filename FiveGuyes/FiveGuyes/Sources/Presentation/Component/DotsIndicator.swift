//
//  DotsIndicator.swift
//  FiveGuyes
//
//  Created by zaehorang on 8/30/25.
//

import SwiftUI

struct DotsIndicator: View {
    let count: Int
    @Binding var selectedIndex: Int?
    
    // Customization
    let dotSize: CGFloat = 6
    let spacing: CGFloat = 4
    let activeColor: Color = Color.Labels.primaryBlack1
    let inactiveColor: Color = Color.Labels.quaternaryBlack4
    let includeTrailingSpacer: Bool = true
    let animation: Animation = .easeInOut(duration: 0.2)
    
    var body: some View {
        if count > 1 {
            HStack(spacing: spacing) {
                ForEach(0..<max(count, 0), id: \.self) { idx in
                    let isSelected = idx == (selectedIndex ?? 0)
                    Circle()
                        .frame(width: dotSize, height: dotSize)
                        .foregroundStyle(isSelected ? activeColor : inactiveColor)
                }
                if includeTrailingSpacer { Spacer() }
            }
            .animation(animation, value: selectedIndex)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedIndex: Int? = 0
        let total = 5

        var body: some View {
            VStack(spacing: 20) {
                DotsIndicator(count: total, selectedIndex: $selectedIndex)

                HStack {
                    Button("← Left") {
                        if let idx = selectedIndex, idx > 0 {
                            selectedIndex = idx - 1
                        }
                    }
                    Button("Right →") {
                        if let idx = selectedIndex, idx < total - 1 {
                            selectedIndex = idx + 1
                        }
                    }
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
