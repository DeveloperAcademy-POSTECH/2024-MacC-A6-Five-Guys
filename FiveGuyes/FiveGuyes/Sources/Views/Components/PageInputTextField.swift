//
//  PageInputTextField.swift
//  FiveGuyes
//
//  Created by 신혜연 on 3/10/25.
//

import UIKit

class PageInputTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) || action == #selector(copy(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
