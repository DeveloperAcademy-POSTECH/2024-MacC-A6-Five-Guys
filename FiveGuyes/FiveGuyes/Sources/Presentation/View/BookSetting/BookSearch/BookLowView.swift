//
//  BookLowView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookRowView: View {
    @ObservedObject var viewModel: BookSearchViewModel
    let book: Book
    
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
                        .cornerRadius(6)
                        .commonShadow()
                    } else {
                        // 이미지 없을 때
                        Rectangle()
                            .foregroundStyle(.green)
                    }
                }
                .frame(width: 115, height: 178)
                .padding(.leading, 20)
                
                VStack(alignment: .leading) {
                    Text(book.title)
                        .fontStyle(.body, weight: .semibold)
                        .foregroundStyle(Color.Labels.primaryBlack1)
                    
                    Text("\(book.author.removingParenthesesContent()) | \(book.pubDate.extractYear()) | \(book.publisher)")
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
}
