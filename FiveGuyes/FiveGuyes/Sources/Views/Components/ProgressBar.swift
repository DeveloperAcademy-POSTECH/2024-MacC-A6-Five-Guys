//
//  ProgressBar.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

struct ProgressBar: View {
    private let total = 4.0
    var currentPage: Int
    
    var body: some View {
        let progress = CGFloat(Double(currentPage) / total)
        
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .stroke(Color(Color.Separators.gray))
                    .fill(Color(Color.Separators.gray))
                    .frame(height: 2)
                
                Rectangle()
                    .stroke(Color.Colors.green1)
                    .fill(Color.Colors.green1)
                    .frame(width: geometry.size.width * progress, height: 2)
            }
        }
        .frame(height: 0)
    }
}

#Preview {
    ProgressBar(currentPage: 2)
}
