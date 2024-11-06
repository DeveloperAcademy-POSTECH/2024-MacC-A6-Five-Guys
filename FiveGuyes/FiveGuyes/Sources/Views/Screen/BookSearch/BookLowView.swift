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
        VStack {
            HStack {
                VStack {
                    if let coverUrl = book.cover, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 115, height: 178)
                        .cornerRadius(6)
                        .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                    }
                }
                .padding(.leading, 20)
                Spacer()
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    
                    Text("\(book.author.removingParenthesesContent()) | \(book.pubDate.extractYear()) | \(book.publisher)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.leading, 16)
                Button(action: {
                    Task {
                        if !isBookmarked {
                            isBookmarked = true
                            if let pageCount = await viewModel.fetchBookDetails(isbn: book.isbn13) {
                                onBookmark(book.title, pageCount)
                            }
                        }
                    }
                }, label: {
                    Image(isBookmarked ? "circleButtonFilled" : "circleButton")
                        .resizable()
                        .frame(width: 24, height: 24)
                })
                .onChange(of: resetBookmark) { _, newValue in
                    if newValue {
                        isBookmarked = false
                    }
                }
                .padding(.trailing, 25)
            }
            Rectangle()
                .stroke(Color(red: 0.94, green: 0.94, blue: 0.94))
                .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                .frame(height: 1)
                .padding(.vertical, 24)
        }
       
    }
}
