//
//  BookLowView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookRowView: View {
    @State private var isBookmarked = false
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @Binding var resetBookmark: Bool
    var onBookmark: (String, Int) -> Void

    var body: some View {
        HStack {
            if let coverUrl = book.cover, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 75)
                .cornerRadius(5)
            }

            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                Task {
                    if !isBookmarked {
                        isBookmarked = true
                        if let pageCount = await viewModel.fetchBookDetails(isbn: book.isbn13) {
                            onBookmark(book.title, pageCount)
                        }
                    }
                }
            }) { Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(.blue) }
            .onChange(of: resetBookmark) { newValue in
                if newValue {
                    isBookmarked = false
                }
            }
        }
    }
}
