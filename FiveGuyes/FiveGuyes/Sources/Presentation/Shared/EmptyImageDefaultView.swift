//
//  EmptyImageDefaultView.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/13/25.
//

import SwiftUI

struct EmptyImageDefaultView: View {
    var body: some View {
        Rectangle()
            .foregroundStyle(Color.Fills.white)
            .frame(width: 104, height: 161)
            .clipToBookShape()
            .commonShadow()
    }
}

#Preview {
    Color.green.ignoresSafeArea()
        .overlay {
            EmptyImageDefaultView()
        }
}
