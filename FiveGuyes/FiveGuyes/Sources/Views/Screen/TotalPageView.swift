//
//  TotalPageView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct TotalPageView: View {
    let pageCount: Int?
    let title: String?
    
    var body: some View {
        VStack {
            if let title = title {
                Text("Title: \(title)")
                    .font(.title2)
                    .padding(.bottom, 8)
            }
            if let pageCount = pageCount {
                Text("Total Pages: \(pageCount)")
                    .font(.title)
            } else {
                Text("Page count not available")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}
