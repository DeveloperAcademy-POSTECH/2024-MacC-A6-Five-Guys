//
//  CompletionListView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct CompletionListView: View {
    typealias UserBook = UserBookSchemaV1.UserBook
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedBookIndex: Int = 0
    @State var showCompletionAlert: Bool = false
    
    // 완독한 책을 가져오는 쿼리
    @Query(
        filter: #Predicate<UserBook> { $0.isCompleted == true }
//        sort: [SortDescriptor(\UserBook.book.targetEndDate, order: .reverse)]
    )
    private var completedBooks: [UserBook]
    
    let completionAlertMessage = "정말로 내용을 삭제할까요?"
    let completionAlertText = "삭제 후에는 복원할 수 없어요"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("완독 리스트")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            if !completedBooks.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // 가로 스크롤로 completedBooks 보여주기
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(completedBooks.indices, id: \.self) { index in
                                let book = completedBooks[index]
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    if let coverURL = book.book.coverURL, let url = URL(string: coverURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 115, height: 178)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        Image("bookCoverDummy")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 115, height: 178)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(book.book.title )
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                        Text(book.book.author)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                                    }
                                }
                                .frame(width: 115)
                                .onTapGesture {
                                    selectedBookIndex = index
                                }
                                .opacity(selectedBookIndex == index ? 1.0 : 0.3)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 선택된 책의 소감문 및 기타 정보 표시
                    let selectedBook = completedBooks[selectedBookIndex] 
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedBook.completionReview)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.bottom, 10)
                        // TODO: 수정 버튼 추가하기
                        HStack {
                            Text("\(selectedBook.book.targetEndDate.toKoreanDateStringWithoutYear()) 완독완료")
                            Spacer()
                            // TODO: ❗️❗️❗️ 수정하기 기능 추가
                            // 데이터를 지우니까 튕김
//                            Button {
//                                showCompletionAlert = true
//                            } label: {
//                                Image(systemName: "ellipsis")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 20, height: 22)
//                                    .tint(Color(red: 0.44, green: 0.44, blue: 0.44))
//                                    .padding(.trailing, 3)
//                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundColor(Color(red: 0.95, green: 0.98, blue: 0.96))
                    }
                    
                }
                
            } else {
                Rectangle()
                    .frame(width: 115, height: 178)
                    .foregroundColor(Color(red: 0.93, green: 0.97, blue: 0.95))
            }
        }
        // TODO: ❗️❗️❗️ 수정하기 기능 추가
        // 데이터를 지우니까 튕김
//        .alert(isPresented: $showCompletionAlert) {
//            Alert(
//                title: Text(completionAlertText),
//                message: Text(completionAlertMessage),
//                primaryButton: .cancel(Text("취소하기")),
//                secondaryButton: .destructive(Text("삭제")) {
//                    let book = completedBooks[selectedBookIndex]
//                    modelContext.delete(book)
//                }
//            )
//        }
    }
}
