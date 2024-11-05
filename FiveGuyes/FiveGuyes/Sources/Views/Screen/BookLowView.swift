//
//  BookLowView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import Combine
import SwiftUI

struct BookRowView: View {
    @State private var isBookmarked = false
    @State private var cancellable: AnyCancellable?
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @Binding var resetBookmark: Bool // Receive resetBookmark as a binding
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
                if !isBookmarked {
                    isBookmarked = true
                    cancellable = viewModel.fetchBookDetails(isbn: book.isbn13)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("Failed to fetch book details: \(error)")
                            }
                        }, receiveValue: { pageCount in
                            onBookmark(book.title, pageCount)
                        })
                }
            }) { Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(.blue)
            }
            .onChange(of: resetBookmark) { newValue in
                if newValue {
                    isBookmarked = false
                    cancellable?.cancel()
                }
            }
        }
    }
}
