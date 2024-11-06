//
//  BookSearchView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/5/24.
//

import SwiftUI

struct BookSearchView: View {
    @State private var selectedPageCount: Int?
    @State private var isNavigatingToTotalPageView = false
    @State private var resetBookmark = false
    @State private var selectedBookTitle: String?
    @State private var progress: CGFloat = 0.25
        
    var body: some View {
        NavigationView {
            VStack {
                ProgressBar(progress: progress)
                BookListView(resetBookmark: $resetBookmark) { title, pageCount in
                    selectedBookTitle = title
                    selectedPageCount = pageCount
                    isNavigatingToTotalPageView = true
                    resetBookmark = false
                    if progress < 1.0 {
                        progress += 0.25
                    }
                }
                NavigationLink(
                    destination: TotalPageView(pageCount: selectedPageCount, title: selectedBookTitle, progress: progress)
                        .onDisappear {
                            selectedBookTitle = nil
                            selectedPageCount = nil
                            resetBookmark = true
                            if progress > 0.25 {
                                progress -= 0.25
                            }
                        },
                    isActive: $isNavigatingToTotalPageView
                    
                ) {
                    EmptyView()
                }
            }
        }
    }
}
