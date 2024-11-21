//
//  ToastViewModel.swift
//  FiveGuyes
//
//  Created by 신혜연 on 11/20/24.
//

import SwiftUI

class ToastViewModel: ObservableObject {
    @Published var message: String = ""
    @Published var isVisible: Bool = false
    private var timer: Timer?
    
    // 타이머 1.5초
    func showToast(message: String, duration: TimeInterval = 1.0) {
        self.message = message
        self.isVisible = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hideToast()
        }
    }
    
    private func hideToast() {
        withAnimation {
            self.isVisible = false
        }
    }
}
