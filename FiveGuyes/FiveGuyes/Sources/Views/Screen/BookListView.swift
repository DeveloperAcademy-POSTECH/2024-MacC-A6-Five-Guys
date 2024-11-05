//
//  BookListView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookListView: View {
    @StateObject private var viewModel = BookViewModel()
    @State private var searchText = ""
    @Binding var resetBookmark: Bool
    var onBookmark: (String, Int) -> Void

    var body: some View {
        VStack {
            TextField("Search for books", text: $searchText, onCommit: {
                viewModel.searchBooks(query: searchText)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            List(viewModel.books) { book in
                BookRowView(book: book, viewModel: viewModel, resetBookmark: $resetBookmark) { title, pageCount in
                    onBookmark(title, pageCount)
                }
            }
        }
    }
}
