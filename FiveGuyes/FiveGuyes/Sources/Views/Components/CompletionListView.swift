//
//  CompletionListView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftData
import SwiftUI

struct CompletionListView: View {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedBookIndex: Int = 0
    @State var showCompletionAlert: Bool = false
    
    // 완독한 책을 가져오는 쿼리
    // TODO: 책 역순으로 받아오기 🐯🐯🐯🐯🐯
    @Query(
        filter: #Predicate<UserBook> { $0.completionStatus.isCompleted == true }
    )
    private var completedBooks: [UserBook]
    
    let completionAlertMessage = "정말로 내용을 삭제할까요?"
    let completionAlertText = "삭제 후에는 복원할 수 없어요"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("완독 리스트")
                    .fontStyle(.title1, weight: .semibold)
                    .foregroundStyle(Color(Color.Labels.primaryBlack1))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if !completedBooks.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // 가로 스크롤로 completedBooks 보여주기
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(completedBooks.indices, id: \.self) { index in
                                let book = completedBooks[index]
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    if let coverURL = book.bookMetaData.coverURL, let url = URL(string: coverURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 115, height: 178)
                                                .clipped() // 넘어간 부분을 잘라냄
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
                                        Text(book.bookMetaData.title)
                                            .fontStyle(.caption1, weight: .semibold)
                                            .foregroundStyle(Color(Color.Labels.primaryBlack1))
                                        Text(book.bookMetaData.author)
                                            .fontStyle(.caption2)
                                            .foregroundStyle(Color(Color.Labels.secondaryBlack2))
                                    }
                                    .lineLimit(1)
                                }
                                .frame(width: 115)
                                .onTapGesture {
                                    selectedBookIndex = index
                                }
                                .opacity(selectedBookIndex == index ? 1.0 : 0.3)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 선택된 책의 소감문 및 기타 정보 표시
                    let selectedBook = completedBooks[selectedBookIndex] 
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedBook.completionStatus.completionReview)
                            .fontStyle(.body)
                            .foregroundStyle(Color(Color.Labels.primaryBlack1))
                            .padding(.bottom, 10)
                        // TODO: 수정 버튼 추가하기
                        HStack {
                            Text("\(selectedBook.userSettings.targetEndDate.toKoreanDateStringWithoutYear()) 완독완료")
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
//                                    .tint(Color(Color.Labels.secondaryBlack2)) // 디자인 시스템으로 수정
//                                    .padding(.trailing, 3)
//                            }
                        }
                        .fontStyle(.caption2)
                        .foregroundStyle(Color(Color.Labels.secondaryBlack2))
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(Color.Fills.lightGreen))
                    }
                    .padding(.horizontal, 20)
                    
                }
                
            } else {
                Rectangle()
                    .frame(width: 115, height: 178)
                    .foregroundStyle(Color.Fills.lightGreen)
                    .padding(.horizontal, 20)
            }
        }
        // TODO: ❗️❗️❗️ 수정하기 기능 추가
        // 데이터를 지우니까 튕김
        // FontStyle 적용해놓음
//        .alert(isPresented: $showCompletionAlert) {
//            Alert(
//                title: Text(completionAlertText)
//                    .alertFontStyle(.title3, weight: .semibold),
//                message: Text(completionAlertMessage)
//                    .alertFontStyle(.caption1),
//                primaryButton: .cancel(Text("취소하기")),
//                secondaryButton: .destructive(Text("삭제")) {
//                    let book = completedBooks[selectedBookIndex]
//                    modelContext.delete(book)
//                }
//            )
//        }
    }
}
