//
//  MainView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftUI

struct MainView: View {
    @State private var hasData: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            NotificationIconView()
            
            ScrollView {
                if hasData {
                    // DataMainView()
                } else {
                    NoDataMainView()
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    MainView()
}
