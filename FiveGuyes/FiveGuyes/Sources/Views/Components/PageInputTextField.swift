//
//  PageInputTextField.swift
//  FiveGuyes
//
//  Created by 신혜연 on 3/10/25.
//

import SwiftUI
import UIKit

class PageInputTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) || action == #selector(copy(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

// CustomTextField를 사용
// SwiftUI 내에서 UIKit을 사용하려면 UIViewRepresentable을 사용
struct CustomTextFieldRepresentable: UIViewRepresentable {
    @Binding var text: Int
    @Binding var isFocused: Bool
    
    func makeUIView(context: Context) -> PageInputTextField {
        let textField = PageInputTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.font = UIFont.systemFont(ofSize: FontStyle.title2.size, weight: .semibold)
        textField.textColor = UIColor(Color.Colors.green2)
        
        return textField
    }
    
    func updateUIView(_ uiView: PageInputTextField, context: Context) {
        uiView.text = "\(text)"
        
        if isFocused {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextFieldRepresentable
        
        init(parent: CustomTextFieldRepresentable) {
            self.parent = parent
        }
        
        // 입력값을 Int로 변환
        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                if let intValue = Int(textField.text ?? "") {
                    self.parent.text = intValue
                } else {
                    self.parent.text = 0
                }
            }
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}
