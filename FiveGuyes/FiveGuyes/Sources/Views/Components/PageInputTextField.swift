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
    @Binding var text: String
    var isFocused: Bool
    var keyboardType: UIKeyboardType = .numberPad
    private let font = UIFont.systemFont(ofSize: FontStyle.title2.size, weight: .semibold)
    private let textColor = UIColor(Color.Colors.green2)
    private let backgroundColor = UIColor(Color.Fills.lightGreen)
    private let cornerRadius: CGFloat = 8
    private let height: CGFloat = 40
    
    func makeUIView(context: Context) -> PageInputTextField {
        let textField = PageInputTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        configureTextField(textField)
        
        return textField
    }
    
    func updateUIView(_ uiView: PageInputTextField, context: Context) {
        uiView.text = text
        
        if isFocused {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }
    
    func configureTextField(_ textField: PageInputTextField) {
        textField.font = font
        textField.textColor = textColor
        textField.backgroundColor = backgroundColor
        textField.layer.cornerRadius = cornerRadius
        textField.layer.masksToBounds = true
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        textField.setContentHuggingPriority(.required, for: .horizontal)
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextFieldRepresentable

        init(parent: CustomTextFieldRepresentable) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}
