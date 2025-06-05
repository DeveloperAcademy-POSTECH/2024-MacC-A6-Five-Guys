//
//  DividerLine.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/5/25.
//

import SwiftUI

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.Separators.gray)
            .frame(height: 1)
    }
}

#Preview {
    DividerLine()
}
