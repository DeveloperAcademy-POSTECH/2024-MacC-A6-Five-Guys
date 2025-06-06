//
//  ToastView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/19/24.
//

import SwiftUI

struct ToastView: View {
    @ObservedObject var viewModel: ToastViewModel
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                if viewModel.isVisible {
                    Text(viewModel.message)
                        .fontStyle(.body, weight: .semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .foregroundStyle(Color.Fills.white)
                        .background(Color.Backgrounds.gray)
                        .cornerRadius(16)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.isVisible)
                        .zIndex(1)
                }
            }
        }
    }
}

struct ToastTestView: View {
    @StateObject private var toastViewModel = ToastViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Button {
                    toastViewModel.showToast(message: "오늘은 완독하는 마지막날이에요!")
                } label: {
                    Text("Show Toast")
                }
            }
            ToastView(viewModel: toastViewModel)
        }
    }
}

#Preview {
    ToastTestView()
}
