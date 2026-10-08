//
//  BookRowView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookRowView: View {
    let viewModel: BookSearchViewModel
    let book: BookSearchItem

    var body: some View {
        VStack {
            HStack {
                VStack {
                    if let coverUrl = book.coverImageURL, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case let .success(image):
                                image.resizable()
                            case .failure:
                                defaultCover
                            @unknown default:
                                defaultCover
                            }
                        }
                        .cornerRadius(6)
                        .commonShadow()
                    } else {
                        defaultCover
                    }
                }
                .frame(width: 115, height: 178)
                .padding(.leading, 20)

                VStack(alignment: .leading) {
                    Text(book.title)
                        .fontStyle(.body, weight: .semibold)
                        .foregroundStyle(Color.Labels.primaryBlack1)

                    Text(Self.metadataText(for: book))
                        .fontStyle(.caption1)
                        .foregroundStyle(Color.Labels.secondaryBlack2)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.leading, 16)

                Image(systemName: viewModel.selectedBook == book ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(Color.Colors.green1)
                    .padding(.trailing, 25)

            }
        }
        .contentShape(Rectangle()) // 전체 영역이 탭 가능한 영역이 되도록 설정
        .onTapGesture {
            viewModel.selectBook(book) // 전체 뷰를 탭하면 선택된 책 업데이트
        }

        Rectangle()
            .stroke(Color.Separators.gray)
            .fill(Color.Separators.gray)
            .frame(height: 1)
        .padding(.vertical, 24)
    }

    static func metadataText(for book: BookSearchItem) -> String {
        let author = book.author.removingParenthesesContent()
        guard let publishedDate = book.publishedDate else {
            return "\(author) | \(book.publisher)"
        }

        let year = Calendar.app.component(.year, from: publishedDate)
        return "\(author) | \(year) | \(book.publisher)"
    }

    private var defaultCover: some View {
        Rectangle()
            .foregroundStyle(.green)
    }
}

#if DEBUG
#Preview("선택된 책") {
    let book = PreviewSupport.sampleBookSearchItem
    let viewModel: BookSearchViewModel = {
        let model = PreviewSupport.makeBookSearchViewModel()
        model.selectedBook = book
        return model
    }()

    BookRowView(viewModel: viewModel, book: book)
        .padding(.vertical, 24)
}

#Preview("선택되지 않은 책") {
    let book = PreviewSupport.sampleBookSearchItem
    let viewModel = PreviewSupport.makeBookSearchViewModel(
        books: [book],
        selectedBook: nil
    )

    BookRowView(viewModel: viewModel, book: book)
        .padding(.vertical, 24)
}
#endif
