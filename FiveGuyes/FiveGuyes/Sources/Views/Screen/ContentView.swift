//
//  ContentView.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/3/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedPageCount: Int?
    @State private var isNavigatingToTotalPageView = false
    @State private var resetBookmark = false
    @State private var selectedBookTitle: String?
    
    var body: some View {
        NavigationView {
            VStack {
                BookListView(resetBookmark: $resetBookmark) { title, pageCount in
                    selectedBookTitle = title
                    selectedPageCount = pageCount
                    isNavigatingToTotalPageView = true
                    resetBookmark = false
                }
                NavigationLink(
                    destination: TotalPageView(pageCount: selectedPageCount, title: selectedBookTitle)
                        .onDisappear {
                            selectedBookTitle = nil
                            selectedPageCount = nil
                            resetBookmark = true
                        },
                    isActive: $isNavigatingToTotalPageView
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("Book Search")
        }
    }
}
