//
//  DailyProgressView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/5/24.
//

import SwiftUI

struct DailyProgressView: View {
    @State private var bookTitle: String = "프리웨이"
    @State private var pagesToReadToday: Int = 10
    @State private var isCompletionDate: Bool = true
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isCompletionDate ? "오늘은 <\(bookTitle)>를 완독하는\n마지막 날이에요"
                     : "지금까지 읽은 쪽수를\n알려주세요")
                    .font(.system(size: 22))
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.top, 72)
            .padding(.bottom, 107)
            
            HStack {
                Spacer()
                ZStack {
                    TextField("\(pagesToReadToday)", value: $pagesToReadToday, format: .number)
                        .frame(width: 180, height: 68)
                        .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                        .cornerRadius(16)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .focused($isInputActive)
                        .tint(Color.black)
                }
                Text("쪽")
                    .padding(.top, 20)
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack(spacing: 0) {
                    Button {
                        isInputActive = false
                    } label: {
                        Text("완료")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 180)
                    .padding(.vertical, 8)
                    .background(Color.green)
                }
                .padding(0)
            }
        }
        .onAppear {
            isInputActive = true
        }
    }
}

#Preview {
    DailyProgressView()
}
