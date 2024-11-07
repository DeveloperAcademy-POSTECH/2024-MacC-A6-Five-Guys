//
//  KeyboardObserver.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import UIKit

class KeyboardObserver: ObservableObject {
    @Published var keyboardIsVisible: Bool = false
    
    init() {
        addKeyboardObservers()
    }
    
    deinit {
        removeKeyboardObservers()
        print("KeyboardObserver 해제됨")
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            self.keyboardIsVisible = true
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardIsVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}