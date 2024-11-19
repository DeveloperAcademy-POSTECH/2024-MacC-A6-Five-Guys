//
//  ToastView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/19/24.
//

import SwiftUI

struct ToastView: View {
    var message: String
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(Color.gray)
                .cornerRadius(16)
        }
    }
}

class ToastModel: ObservableObject {
    @Published var message: String?
    @Published var isVisible: Bool = false
    private var timer: Timer?
    
    func showToast(message: String, duration: TimeInterval = 1.0) {
        self.message = message
        self.isVisible = true
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation {
                    self?.isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.message = nil
                }
            }
        }
    }
}

    struct ToastTestView: View {
        @StateObject private var toastViewModel = ToastModel()
        
        var body: some View {
            ZStack {
                VStack {
                    Button("Show Toast") {
                        toastViewModel.showToast(message: "오늘은 완독하는 마지막 날이에요!")
                    }
                }
                
                if let message = toastViewModel.message {
                    ToastView(message: message)
                        .opacity(toastViewModel.isVisible ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: toastViewModel.isVisible)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }

#Preview {
    ToastTestView()
}
