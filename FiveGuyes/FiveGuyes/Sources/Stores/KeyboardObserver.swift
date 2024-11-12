//
//  KeyboardObserver.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import UIKit

// MARK: - 키보드가 올라오는 시점을 알기 위한 모델
final class KeyboardObserver: ObservableObject {
    @Published var keyboardIsVisible: Bool = false
    
    init() {
        addKeyboardObservers()
    }
    
    deinit {
        removeKeyboardObservers()
        print("KeyboardObserver 해제됨")
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.async {
                self?.keyboardIsVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.async {
                self?.keyboardIsVisible = false
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
