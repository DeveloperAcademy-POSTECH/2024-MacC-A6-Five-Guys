//
//  BookPageSettingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

// TODO: 전체 페이지 못받아오는 거 해결하기
// TODO: 책 정보를 다음 페이지로 넘길 방식 찾기 (현재는 한 개씩 보내는데 그러다보면 점점 추가될 듯;) 
// TODO: 날짜 선택 달력 리팩하기
// TODO: 프로그레스바 추가하기 (한 화면에서 동작해야지 애니메이션이 돌아갈 듯;)

struct BookPageSettingView: View {
    // TODO: Book 타입 받기
    let selectedBook: Book
    
    @State var pageCount: String
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @FocusState private var textFieldActive: Bool
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    var body: some View {
        let title = selectedBook.title
        
        VStack {
            VStack(alignment: .leading) {
                Text("<\(title)>\(title.subjectParticle())")
                    .lineLimit(nil) // 제목이 길어지면 줄바꿈 허용
                    .padding(.top, 35)
                
                HStack(spacing: 8) {
                    Text("총")
                    
                    HStack(spacing: 2) {
                        TextField("", text: $pageCount)
                            .keyboardType(.numberPad)
                            .focused($textFieldActive)
                            .font(.system(size: 20, weight: .medium))
                            .fixedSize()
                            .background {
                                RoundedRectangle(cornerRadius: 7)
                                    .foregroundColor(.clear)
                                    .frame(height: 30) // 텍스트 필드 높이 지정
                            }
                        
                        Image(systemName: "pencil") // 원하는 이미지로 변경
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        
                    }
                    .foregroundColor(Color(red: 0.03, green: 0.68, blue: 0.41))
                    .padding(.horizontal, 8) // 텍스트 필드와 이미지 주변 패딩
                    .padding(.vertical, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(Color(red: 0.93, green: 0.97, blue: 0.95))
                    }
                    
                    Text("쪽이에요")
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            if keyboardObserver.keyboardIsVisible {
                Button {
                    navigationCoordinator.push(.bookDurationSetting)
                } label: {
                    Text("다음")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.07, green: 0.87, blue: 0.54))
                        .foregroundStyle(.white)
                    
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
        }
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(.black)
        .onAppear {
            textFieldActive = true
        }
        .customNavigationBackButton()
    }
}

#Preview {
    BookPageSettingView(selectedBook: Book(title: "aaa", author: "Aaa", cover: nil, publisher: "Aaa", isbn13: "Aaa", pubDate: "aaa"), pageCount: "150")
}
