//
//  BookPageSettingView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct BookPageSettingView: View {
    
    @State var totalPages: String
    
    @Environment(NavigationCoordinator.self) var navigationCoordinator: NavigationCoordinator
    @Environment(BookSettingInputModel.self) var bookSettingInputModel: BookSettingInputModel
    
    @FocusState private var isTextTextFieldFocused: Bool
    
    var body: some View {
        let title = bookSettingInputModel.selectedBook!.title
        
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("<\(title)>\(title.subjectParticle())")
                    .lineLimit(nil) // 제목이 길어지면 줄바꿈 허용
                
                HStack(spacing: 8) {
                    Text("총")
                    
                    HStack(spacing: 2) {
                        TextField("", text: $totalPages)
                            .keyboardType(.numberPad)
                            .focused($isTextTextFieldFocused)
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
            .padding(.top, 34)
            .padding(.horizontal, 20)
            
            Spacer()
            
            if isTextTextFieldFocused {
                Button {
                    bookSettingInputModel.totalPages = totalPages
                    isTextTextFieldFocused = false
                    bookSettingInputModel.nextPage()
                    
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Text("완료")
                        .foregroundColor(Color(red: 0.84, green: 0.84, blue: 0.84))
                }
                .disabled(true)
            }
        }
        .onAppear {
            totalPages = bookSettingInputModel.totalPages
            isTextTextFieldFocused = true
        }
    }
}
