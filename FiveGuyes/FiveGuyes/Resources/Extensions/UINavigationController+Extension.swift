//
//  UINavigationController+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/4/24.
//

import UIKit

// MARK: - Custom Navigation Bar의 Back Swipe 액션 활성화
extension UINavigationController: ObservableObject, UIGestureRecognizerDelegate {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
