//
//  TotalPageView.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/4/24.
//

import SwiftUI

struct TotalPageView: View {
    
    @State var pageCount: Int?
    @State private var editablePageCount: String = ""
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool

    let title: String?
    let progress: CGFloat
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    var body: some View {
        
            ProgressBar(progress: progress)
        VStack(alignment: .leading) {
            if let title = title {
                Text("<\(title)> \(title.subjectParticle())")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            }
            HStack {
                Text("총")
                    .font(.system(size: 22))
                    .frame(width: 21, alignment: .topLeading)
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                TextField("", text: $editablePageCount, onCommit: {
                    if let newPageCount = Int(editablePageCount) {
                        pageCount = newPageCount
                    }
                })
                .customStyleFieldPageCount(placeholder: "\(editablePageCount)", text: $editablePageCount)
                .frame(width: max(80, CGFloat(editablePageCount.count) * 10 + 15))
                .keyboardType(.numberPad)
                .onAppear {
                    if let pageCount = pageCount {
                        editablePageCount = "\(pageCount)"
                    }
                    isEditing = false
                }
               
                Text("쪽이에요")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            }
            Spacer()
           
        }.padding(.horizontal, 20)
        if keyboardObserver.keyboardIsVisible {
            Button {
                // 다음 화면으로 넘어감(기간설정화면)
            } label: {
                Text("다음")
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.green)
                    .foregroundStyle(.white)
                
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}
