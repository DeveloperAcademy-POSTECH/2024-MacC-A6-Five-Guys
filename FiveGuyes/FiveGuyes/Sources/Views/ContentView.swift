//
//  ContentView.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/3/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                NavigationLink(destination: ImageTestingView()) {
                    Text("Go to Image Testing View")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Main View") // 네비게이션 바의 제목 설정
        }
    }
}

#Preview {
    ContentView()
}
