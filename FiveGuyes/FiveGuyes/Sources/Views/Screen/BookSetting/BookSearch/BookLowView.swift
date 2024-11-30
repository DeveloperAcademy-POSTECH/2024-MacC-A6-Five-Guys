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
                        .shadow(color: Color(red: 0.84, green: 0.84, blue: 0.84).opacity(0.25), radius: 2, x: 0, y: 4)
                    } else {
                        // 이미지 없을 때
                        Rectangle()
                            .foregroundColor(.green)
                    }
                }
                .frame(width: 115, height: 178)
                .padding(.leading, 20)
                
                VStack(alignment: .leading) {
                    Text(book.title)
                        .fontStyle(.body, weight: .semibold)
                        .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                    
                    Text("\(book.author.removingParenthesesContent()) | \(book.pubDate.extractYear()) | \(book.publisher)")
                        .fontStyle(.caption1)
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
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
            .stroke(Color(red: 0.94, green: 0.94, blue: 0.94))
            .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
            .frame(height: 1)
            .padding(.vertical, 24)
    }
}
