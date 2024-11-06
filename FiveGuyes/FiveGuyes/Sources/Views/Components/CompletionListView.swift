//
//  CompletionListView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/5/24.
//

import SwiftUI

struct CompletionListView: View {
    @State private var isEmptyCompletionBook = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("완독 리스트")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            if !isEmptyCompletionBook {
                
                VStack(alignment: .leading, spacing: 6) {
                    Image("bookCoverDummy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 115, height: 178)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("프리웨이")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        Text("드로우앤드류")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("나를 위해 잘 살아간다는 것은 무엇일까를 곰곰이 생각해 보게 되었다!\n\n용기가 필요할 때마다 다시 만나고 싶은 책 🥹")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.bottom, 10)
                    
                    HStack {
                        
                        Text("11월 30일 완독완료")
                        Spacer()
                        
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.44))
                    
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(Color(red: 0.95, green: 0.98, blue: 0.96))
                }
                
            } else {
                Rectangle()
                    .frame(width: 115, height: 178)
                    .foregroundColor(Color(red: 0.93, green: 0.97, blue: 0.95))
            }
        }
    }
}

#Preview {
    CompletionListView()
}
