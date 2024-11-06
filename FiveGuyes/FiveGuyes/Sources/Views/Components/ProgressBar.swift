//
//  ProgressBar.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

struct ProgressBar: View {
    var progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .stroke(Color(red: 0.94, green: 0.94, blue: 0.94))
                    .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    .frame(height: 2)
                Rectangle()
                    .stroke(Color(red: 0.07, green: 0.87, blue: 0.54))
                    .fill(Color(red: 0.07, green: 0.87, blue: 0.54))
                    .frame(width: geometry.size.width * progress, height: 2)
            }
        }
        .frame(height: 0)
        .padding(.bottom, 24)
    }
}
